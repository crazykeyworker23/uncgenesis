import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/providers/core_providers.dart';
import '../../../../core/utils/api_error.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../data/models/leader_models.dart';
import '../../data/repositories/leader_repository_impl.dart';
import '../../domain/repositories/leader_repository.dart';

final leaderRepositoryProvider = Provider<LeaderRepository>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return LeaderRepositoryImpl(dio: apiClient.dio);
});

/// Células que la sesión tiene a su cargo.
///
/// Depende de la identidad de la sesión para volver a pedirse al entrar o
/// salir: sin eso, cerrar sesión dejaba en pantalla la célula del anterior.
final myCellsProvider = FutureProvider<MyCells>((ref) async {
  final auth = ref.watch(authProvider);
  if (!auth.isAuthenticated) return const MyCells();
  return ref.watch(leaderRepositoryProvider).getMyCells();
});

/// Célula sobre la que se está trabajando.
///
/// El líder tiene una sola y no llega a elegir; el coordinador y el pastorado
/// alcanzan varias y necesitan cambiar entre ellas.
final selectedCellIdProvider = StateProvider<int?>((ref) => null);

/// Célula activa ya resuelta: la elegida, o la primera si aún no se eligió.
final activeCellProvider = Provider<LeaderCell?>((ref) {
  final myCells = ref.watch(myCellsProvider).valueOrNull;
  final cells = myCells?.cells ?? const <LeaderCell>[];
  if (cells.isEmpty) return null;

  final selectedId = ref.watch(selectedCellIdProvider);
  if (selectedId != null) {
    for (final cell in cells) {
      if (cell.id == selectedId) return cell;
    }
    // La selección guardada ya no está dentro del alcance (cambió el rol o se
    // reasignó la célula): se sigue adelante con la primera en lugar de
    // quedarse en blanco.
  }

  // Se empieza por una que además se pueda gestionar. El coordinador que
  // pertenece a una célula ajena la alcanza igual, y sin esto podría abrir la
  // sección sobre un grupo en el que no puede tocar nada.
  final managed = myCells?.managed ?? const <LeaderCell>[];
  return managed.isNotEmpty ? managed.first : cells.first;
});

/// Alcance vigente sobre las células.
///
/// Se prefiere el del perfil porque llega con la sesión y no obliga a esperar
/// otra petición; `my-cells` lo repite y sirve de respaldo.
final cellScopeProvider = Provider<SessionScope>((ref) {
  final fromProfile = ref.watch(authProvider).user?.scope;
  if (fromProfile != null && (fromProfile.managesAnyCell || fromProfile.cellIds.isNotEmpty)) {
    return fromProfile;
  }
  return ref.watch(myCellsProvider).valueOrNull?.scope ?? const SessionScope();
});

/// `true` cuando la sesión puede entrar a la sección de gestión de célula.
///
/// Pertenecer a una célula no cuenta: un miembro corriente aparece en el
/// alcance de su grupo y no debe ver la gestión.
final leadsAnyCellProvider = Provider<bool>((ref) {
  return ref.watch(authProvider).user?.leadsAnyCell ?? false;
});

/// `true` cuando la aplicación debe ordenarse alrededor de la célula.
///
/// Es más estrecho que [leadsAnyCellProvider]: reordenar la navegación se
/// reserva a quien responde de un grupo concreto. El pastorado alcanza todas
/// las células, pero en el teléfono es un miembro más de la iglesia y su
/// herramienta de administración es el panel.
final worksAsCellLeaderProvider = Provider<bool>((ref) {
  return ref.watch(authProvider).user?.scope.hasOwnCells ?? false;
});

/// `true` si se puede registrar y modificar en la célula activa.
///
/// El coordinador consulta las células que supervisa pero no siempre escribe
/// en ellas; con esto la pantalla enseña los datos sin ofrecer botones que el
/// servidor va a rechazar.
final canManageActiveCellProvider = Provider<bool>((ref) {
  final cell = ref.watch(activeCellProvider);
  if (cell == null) return false;
  return ref.watch(cellScopeProvider).canManage(cell.id);
});

final cellStatisticsProvider = FutureProvider.family<CellStatistics, int>((ref, cellId) {
  return ref.watch(leaderRepositoryProvider).getStatistics(cellId);
});

final cellMembersProvider = FutureProvider.family<List<CellMember>, int>((ref, cellId) {
  return ref.watch(leaderRepositoryProvider).getMembers(cellId);
});

// ── Listas paginadas ────────────────────────────────────────────────────────
// El servidor entrega diez por página. Reuniones, seguimientos e informes se
// acumulan igual, así que comparten el mismo mecanismo en lugar de repetirlo
// tres veces.

class PagedListState<T> {
  final List<T> items;
  final bool isLoading;
  final bool hasMore;
  final String? errorMessage;

  const PagedListState({
    this.items = const [],
    this.isLoading = false,
    this.hasMore = true,
    this.errorMessage,
  });

  /// `true` mientras se carga la primera página y todavía no hay nada que ver.
  bool get isLoadingFirstPage => isLoading && items.isEmpty;

  bool get isEmpty => !isLoading && items.isEmpty && errorMessage == null;

  PagedListState<T> copyWith({
    List<T>? items,
    bool? isLoading,
    bool? hasMore,
    String? errorMessage,
    bool clearError = false,
  }) {
    return PagedListState<T>(
      items: items ?? this.items,
      isLoading: isLoading ?? this.isLoading,
      hasMore: hasMore ?? this.hasMore,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}

class PagedListNotifier<T> extends StateNotifier<PagedListState<T>> {
  final Future<Paged<T>> Function(int page) _fetch;
  final String _fallbackError;
  int _page = 1;

  /// Distingue la carga en curso de las anteriores: al refrescar mientras una
  /// página seguía viajando, la respuesta vieja llegaba después y volvía a
  /// añadir elementos ya mostrados.
  int _requestToken = 0;

  /// El estado inicial NO puede escribirse como `const PagedListState()`: en un
  /// contexto constante Dart no puede quedarse con la `T` de esta clase y
  /// construye un `PagedListState<Never>`. La lista arrancaba entonces con un
  /// `items` de tipo `List<Never>` y el primer `copyWith` reventaba con «type
  /// 'List<CellMeeting>' is not a subtype of type 'List<Never>?'», dejando
  /// vacías todas las listas de la sección.
  ///
  /// Arranca cargando: si no, entre la construcción y la primera petición la
  /// pantalla enseñaba durante un instante el mensaje de «no hay nada».
  PagedListNotifier(this._fetch, {String fallbackError = 'No pudimos cargar la información.'})
      : _fallbackError = fallbackError,
        super(PagedListState<T>(isLoading: true)) {
    Future.microtask(_loadFirstPage);
  }

  /// La primera página la pide el constructor, que ya dejó `isLoading` puesto.
  Future<void> _loadFirstPage() => _fetchPage(force: true);

  Future<void> loadMore() => _fetchPage();

  Future<void> _fetchPage({bool force = false}) async {
    if (!force && (state.isLoading || !state.hasMore)) return;

    final token = ++_requestToken;
    state = state.copyWith(isLoading: true, clearError: true);

    try {
      final page = await _fetch(_page);
      if (token != _requestToken || !mounted) return;
      _page++;
      state = state.copyWith(
        items: [...state.items, ...page.items],
        isLoading: false,
        hasMore: page.hasMore,
        clearError: true,
      );
    } catch (error) {
      if (token != _requestToken || !mounted) return;
      state = state.copyWith(
        isLoading: false,
        hasMore: false,
        errorMessage: ApiError.message(error, fallback: _fallbackError),
      );
    }
  }

  Future<void> refresh() async {
    _requestToken++;
    _page = 1;
    state = PagedListState<T>(isLoading: true);
    await _fetchPage(force: true);
  }
}

final cellMeetingsProvider = StateNotifierProvider.family<PagedListNotifier<CellMeeting>,
    PagedListState<CellMeeting>, int>((ref, cellId) {
  final repository = ref.watch(leaderRepositoryProvider);
  return PagedListNotifier<CellMeeting>(
    (page) => repository.getMeetings(cellId, page: page),
    fallbackError: 'No pudimos cargar las reuniones.',
  );
});

/// La reunión más reciente a la que todavía no se le pasó lista.
///
/// `null` cuando están todas al día. La lista llega ordenada de más nueva a
/// más antigua, así que la primera sin asistencia es la que toca.
///
/// Lo usan el aviso de pendientes y el atajo «Pasar lista» del inicio: los dos
/// hablan de la misma reunión, y antes cada uno la buscaba por su cuenta.
final pendingRollCallProvider = Provider.family<CellMeeting?, int>((ref, cellId) {
  for (final meeting in ref.watch(cellMeetingsProvider(cellId)).items) {
    if (!meeting.hasAttendance) return meeting;
  }
  return null;
});

/// Una reunión concreta, para la pantalla de pase de lista.
///
/// Se vuelve a pedir al servidor en lugar de arrastrar el objeto de la lista:
/// así la pantalla funciona igual si se llega desde una notificación o
/// recargando la ruta, y no muestra una asistencia desactualizada.
final cellMeetingProvider = FutureProvider.family<CellMeeting, int>((ref, meetingId) {
  return ref.watch(leaderRepositoryProvider).getMeeting(meetingId);
});

final cellFollowUpsProvider = StateNotifierProvider.family<PagedListNotifier<MemberFollowUp>,
    PagedListState<MemberFollowUp>, int>((ref, cellId) {
  final repository = ref.watch(leaderRepositoryProvider);
  return PagedListNotifier<MemberFollowUp>(
    (page) => repository.getFollowUps(cellId, page: page),
    fallbackError: 'No pudimos cargar los seguimientos.',
  );
});

final cellReportsProvider = StateNotifierProvider.family<PagedListNotifier<CellReport>,
    PagedListState<CellReport>, int>((ref, cellId) {
  final repository = ref.watch(leaderRepositoryProvider);
  return PagedListNotifier<CellReport>(
    (page) => repository.getReports(cellId, page: page),
    fallbackError: 'No pudimos cargar los informes.',
  );
});
