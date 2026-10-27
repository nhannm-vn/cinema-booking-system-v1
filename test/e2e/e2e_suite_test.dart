import 'package:flutter_test/flutter_test.dart';

import 'test_fixtures.dart';
import 'tier1_feature_test.dart' as tier1;
import 'tier2_boundary_test.dart' as tier2;
import 'tier3_pairwise_test.dart' as tier3;
import 'tier4_application_scenarios_test.dart' as tier4;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    await initTestSupabase();
  });

  group('MASTER E2E TEST SUITE: CINEMA BOOKING & OPERATION MANAGEMENT APP', () {
    tier1.main();
    tier2.main();
    tier3.main();
    tier4.main();
  });
}
