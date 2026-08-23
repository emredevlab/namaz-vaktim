import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:namaz_vaktim/core/app_open_ad_manager.dart';

void main() {
  group('AppOpenAdManager.shouldShowOnResume', () {
    test('resumed + loaded + not showing => true', () {
      expect(
        AppOpenAdManager.shouldShowOnResume(
          adLoaded: true,
          isShowing: false,
          state: AppLifecycleState.resumed,
        ),
        isTrue,
      );
    });

    test('paused => false (reklam yalnızca resume anında gösterilir)', () {
      expect(
        AppOpenAdManager.shouldShowOnResume(
          adLoaded: true,
          isShowing: false,
          state: AppLifecycleState.paused,
        ),
        isFalse,
      );
    });

    test('detached => false', () {
      expect(
        AppOpenAdManager.shouldShowOnResume(
          adLoaded: true,
          isShowing: false,
          state: AppLifecycleState.detached,
        ),
        isFalse,
      );
    });

    test('hidden => false', () {
      expect(
        AppOpenAdManager.shouldShowOnResume(
          adLoaded: true,
          isShowing: false,
          state: AppLifecycleState.hidden,
        ),
        isFalse,
      );
    });

    test('inactive => false', () {
      expect(
        AppOpenAdManager.shouldShowOnResume(
          adLoaded: true,
          isShowing: false,
          state: AppLifecycleState.inactive,
        ),
        isFalse,
      );
    });

    test('resumed ama reklam yüklenmemişse => false', () {
      expect(
        AppOpenAdManager.shouldShowOnResume(
          adLoaded: false,
          isShowing: false,
          state: AppLifecycleState.resumed,
        ),
        isFalse,
      );
    });

    test('resumed ama zaten gösteriliyorsa => false', () {
      expect(
        AppOpenAdManager.shouldShowOnResume(
          adLoaded: true,
          isShowing: true,
          state: AppLifecycleState.resumed,
        ),
        isFalse,
      );
    });

    test('yüklenmemiş ve gösteriliyorken resumed => false', () {
      expect(
        AppOpenAdManager.shouldShowOnResume(
          adLoaded: false,
          isShowing: true,
          state: AppLifecycleState.resumed,
        ),
        isFalse,
      );
    });

    test('tüm state x loaded x showing kombinasyonları', () {
      const states = <AppLifecycleState, bool>{
        AppLifecycleState.resumed: true,
        AppLifecycleState.inactive: false,
        AppLifecycleState.hidden: false,
        AppLifecycleState.paused: false,
        AppLifecycleState.detached: false,
      };
      states.forEach((state, expectedWhenReady) {
        expect(
          AppOpenAdManager.shouldShowOnResume(
            adLoaded: true,
            isShowing: false,
            state: state,
          ),
          expectedWhenReady,
          reason: '$state + loaded + not showing beklenen: $expectedWhenReady',
        );
        expect(
          AppOpenAdManager.shouldShowOnResume(
            adLoaded: false,
            isShowing: false,
            state: state,
          ),
          isFalse,
          reason: '$state + not loaded her zaman false olmalı',
        );
        expect(
          AppOpenAdManager.shouldShowOnResume(
            adLoaded: true,
            isShowing: true,
            state: state,
          ),
          isFalse,
          reason: '$state + showing her zaman false olmalı',
        );
        expect(
          AppOpenAdManager.shouldShowOnResume(
            adLoaded: false,
            isShowing: true,
            state: state,
          ),
          isFalse,
          reason: '$state + not loaded + showing her zaman false olmalı',
        );
      });
    });
  });
}
