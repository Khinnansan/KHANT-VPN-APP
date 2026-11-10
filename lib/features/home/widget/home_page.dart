
import 'package:dartx/dartx.dart';
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:hiddify/core/app_info/app_info_provider.dart';
import 'package:hiddify/core/localization/translations.dart';
import 'package:hiddify/core/router/bottom_sheets/bottom_sheets_notifier.dart';
import 'package:hiddify/features/home/widget/connection_button.dart';
import 'package:hiddify/features/profile/notifier/active_profile_notifier.dart';
import 'package:hiddify/features/profile/widget/profile_tile.dart';
import 'package:hiddify/features/proxy/active/active_proxy_card.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:sliver_tools/sliver_tools.dart';

const Color _gold = Color(0xFFD6AD55);
const Color _goldLight = Color(0xFFF3D991);
const Color _darkBackground = Color(0xFF080808);
const Color _cardBackground = Color(0xFF15130F);

class HomePage extends HookConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = ref.watch(translationsProvider).requireValue;
    final activeProfile = ref.watch(activeProfileProvider);

    return Scaffold(
      backgroundColor: _darkBackground,
      appBar: AppBar(
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: _darkBackground,
        surfaceTintColor: Colors.transparent,
        titleSpacing: 18,
        title: Row(
          children: [
            Container(
              height: 39,
              width: 39,
              padding: const EdgeInsets.all(3),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: _gold.withValues(alpha: .65),
                ),
                gradient: const LinearGradient(
                  colors: [
                    Color(0xFF302516),
                    Color(0xFF100E0A),
                  ],
                ),
              ),
              child: Image.asset(
                'assets/images/khant_vpn_icon.png',
                fit: BoxFit.contain,
              ),
            ),
            const Gap(11),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'KHANT VPN',
                  style: TextStyle(
                    color: _goldLight,
                    fontSize: 17,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.5,
                  ),
                ),
                const Text(
                  'PREMIUM PRIVATE NETWORK',
                  style: TextStyle(
                    color: Colors.white54,
                    fontSize: 8,
                    letterSpacing: 1.4,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const Gap(7),
            const AppVersionLabel(),
          ],
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 14),
            decoration: BoxDecoration(
              color: _gold.withValues(alpha: .10),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: _gold.withValues(alpha: .35),
              ),
            ),
            child: Semantics(
              key: const ValueKey("profile_add_button"),
              label: t.pages.profiles.add,
              child: IconButton(
                icon: const Icon(
                  Icons.add_rounded,
                  color: _goldLight,
                  size: 27,
                ),
                onPressed: () => ref
                    .read(bottomSheetsNotifierProvider.notifier)
                    .showAddProfile(),
              ),
            ),
          ),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF17130C),
              Color(0xFF090909),
              Color(0xFF050505),
            ],
          ),
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Positioned(
              top: -100,
              left: -100,
              right: -100,
              child: Container(
                height: 300,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: _gold.withValues(alpha: .09),
                      blurRadius: 120,
                      spreadRadius: 35,
                    ),
                  ],
                ),
              ),
            ),
            Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 600),
                child: CustomScrollView(
                  physics: const BouncingScrollPhysics(),
                  slivers: [
                    MultiSliver(
                      children: [
                        switch (activeProfile) {
                          AsyncData(value: final profile?) => Padding(
                              padding: const EdgeInsets.fromLTRB(
                                15,
                                12,
                                15,
                                8,
                              ),
                              child: Container(
                                decoration: BoxDecoration(
                                  color: _cardBackground,
                                  borderRadius: BorderRadius.circular(19),
                                  border: Border.all(
                                    color: _gold.withValues(alpha: .28),
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(
                                        alpha: .3,
                                      ),
                                      blurRadius: 15,
                                      offset: const Offset(0, 5),
                                    ),
                                  ],
                                ),
                                child: ProfileTile(
                                  profile: profile,
                                  isMain: true,
                                  margin: const EdgeInsets.symmetric(
                                    horizontal: 4,
                                    vertical: 4,
                                  ),
                                ),
                              ),
                            ),
                          _ => const SizedBox.shrink(),
                        },
                        SliverFillRemaining(
                          hasScrollBody: false,
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(
                              18,
                              12,
                              18,
                              24,
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Spacer(flex: 2),
                                Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 24,
                                    horizontal: 12,
                                  ),
                                  decoration: BoxDecoration(
                                    color: _cardBackground.withValues(
                                      alpha: .88,
                                    ),
                                    borderRadius: BorderRadius.circular(28),
                                    border: Border.all(
                                      color: _gold.withValues(alpha: .30),
                                      width: 1,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: _gold.withValues(alpha: .07),
                                        blurRadius: 35,
                                        spreadRadius: 1,
                                      ),
                                      BoxShadow(
                                        color: Colors.black.withValues(
                                          alpha: .5,
                                        ),
                                        blurRadius: 20,
                                        offset: const Offset(0, 10),
                                      ),
                                    ],
                                  ),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Container(
                                            width: 6,
                                            height: 6,
                                            decoration: const BoxDecoration(
                                              color: _gold,
                                              shape: BoxShape.circle,
                                            ),
                                          ),
                                          const Gap(8),
                                          const Text(
                                            'SECURE CONNECTION',
                                            style: TextStyle(
                                              color: _goldLight,
                                              fontSize: 11,
                                              fontWeight: FontWeight.w800,
                                              letterSpacing: 2,
                                            ),
                                          ),
                                          const Gap(8),
                                          Container(
                                            width: 6,
                                            height: 6,
                                            decoration: const BoxDecoration(
                                              color: _gold,
                                              shape: BoxShape.circle,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const Gap(22),
                                      const ConnectionButton(),
                                    ],
                                  ),
                                ),
                                const Spacer(flex: 2),
                                Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.all(13),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF12110E),
                                    borderRadius: BorderRadius.circular(17),
                                    border: Border.all(
                                      color: _gold.withValues(alpha: .20),
                                    ),
                                  ),
                                  child: const ActiveProxyFooter(),
                                ),
                                const Gap(24),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class AppVersionLabel extends HookConsumerWidget {
  const AppVersionLabel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = ref.watch(translationsProvider).requireValue;
    final version = ref.watch(appInfoProvider).requireValue.presentVersion;

    if (version.isBlank) return const SizedBox();

    return Semantics(
      label: t.common.version,
      button: false,
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF302516),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: _gold.withValues(alpha: .45),
          ),
        ),
        padding: const EdgeInsets.symmetric(
          horizontal: 6,
          vertical: 3,
        ),
        child: Text(
          version,
          textDirection: TextDirection.ltr,
          style: const TextStyle(
            color: _goldLight,
            fontSize: 9,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}
