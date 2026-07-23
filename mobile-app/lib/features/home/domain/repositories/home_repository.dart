import '../../data/models/public_settings_model.dart';
import '../../../publications/data/models/publication_model.dart';
import '../../../devotionals/data/models/devotional_model.dart';
import '../../../events/data/models/event_model.dart';

abstract class HomeRepository {
  Future<PublicSettingsModel> getPublicSettings();
  Future<List<PublicationModel>> getRecentPublications();
  Future<DevotionalModel?> getTodayDevotional();
  Future<List<EventModel>> getUpcomingEvents();
}
