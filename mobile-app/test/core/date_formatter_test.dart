import 'package:flutter_test/flutter_test.dart';
import 'package:genesis_app/core/utils/date_formatter.dart';

void main() {
  group('Cuándo ocurre algo con principio y fin', () {
    // Un evento de varios días se anunciaba con la fecha de inicio a secas:
    // parecía de un solo día y no se sabía hasta cuándo se podía ir.

    test('de un solo día se dice como un día', () {
      expect(
        DateFormatter.dateRange('2026-08-04T19:00:00', '2026-08-04T21:00:00'),
        'Martes 4 de agosto',
      );
    });

    test('de varios días dentro del mismo mes se dice del uno al otro', () {
      expect(
        DateFormatter.dateRange('2026-08-04T19:00:00', '2026-08-06T21:00:00'),
        'Del 4 al 6 de agosto',
      );
    });

    test('a caballo entre dos meses nombra los dos', () {
      expect(
        DateFormatter.dateRange('2026-07-30T19:00:00', '2026-08-02T21:00:00'),
        'Del 30 de julio al 2 de agosto',
      );
    });

    test('sin fecha de fin se comporta como antes', () {
      expect(DateFormatter.dateRange('2026-08-04T19:00:00', null), 'Martes 4 de agosto');
    });

    test('sin fecha de inicio avisa en lugar de romperse', () {
      expect(DateFormatter.dateRange(null, '2026-08-06'), 'Fecha por confirmar');
    });
  });

  group('Horario', () {
    test('en un solo día se dan las dos horas', () {
      expect(
        DateFormatter.timeRange('2026-08-04T19:00:00', '2026-08-04T21:30:00'),
        '07:00 PM a 09:30 PM',
      );
    });

    test('en varios días la hora de fin no aporta nada', () {
      // Decir «07:00 PM a 09:30 PM» en algo que dura tres días confunde: para
      // eso está el rango de fechas.
      expect(
        DateFormatter.timeRange('2026-08-04T19:00:00', '2026-08-06T21:30:00'),
        '07:00 PM',
      );
    });

    test('sin hora no se inventa una', () {
      expect(DateFormatter.timeRange('2026-08-04', '2026-08-06'), isNull);
    });
  });
}
