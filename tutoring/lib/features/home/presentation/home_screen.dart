import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:tutoring/core/router/app_routes.dart';
import 'package:tutoring/core/theme/app_colors.dart';
import 'package:tutoring/core/theme/app_tokens.dart';
import 'package:tutoring/core/widgets/app_page_frame.dart';
import 'package:tutoring/core/widgets/app_responsive_scaffold.dart';
import 'package:tutoring/core/widgets/dashed_border.dart';
import 'package:tutoring/features/auth/domain/entities/user_role.dart';
import 'package:tutoring/features/auth/presentation/controllers/auth_providers.dart';
import 'package:tutoring/features/classes/domain/entities/study_class.dart';
import 'package:tutoring/features/classes/presentation/controllers/class_providers.dart';
import 'package:tutoring/features/classes/presentation/widgets/class_add_sheet.dart';
import 'package:tutoring/features/classes/presentation/widgets/class_info_sheet.dart';
import 'package:tutoring/features/home/presentation/controllers/home_summary.dart';
import 'package:tutoring/features/home/presentation/widgets/home_bottom_nav.dart';
import 'package:tutoring/features/home/presentation/widgets/home_search_sheet.dart';
import 'package:tutoring/features/notes/domain/entities/study_note.dart';
import 'package:tutoring/features/notes/presentation/controllers/note_providers.dart';
import 'package:tutoring/features/notifications/presentation/controllers/notification_providers.dart';
import 'package:tutoring/features/notifications/presentation/widgets/notification_sheet.dart';
import 'package:tutoring/features/quizzes/domain/entities/quiz_attempt.dart';
import 'package:tutoring/features/quizzes/presentation/controllers/quiz_providers.dart';
import 'package:tutoring/features/reviews/domain/entities/review_item.dart';
import 'package:tutoring/features/reviews/presentation/controllers/review_providers.dart';

const _assetRoot = 'assets/images/home';

/// 01_Home / 01_Home_Empty: greeting, the day's summary, my classes as book
/// covers (1 / 2 / 3 columns), and the 홈·마이 tabs below desktop.
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  /// Key of the class card for [classId]; tests read the grid from it.
  static Key classCardKey(String classId) => Key('class-card-$classId');

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authStateProvider).asData?.value;
    if (user == null) {
      return const Scaffold(
        backgroundColor: AppColors.background,
        body: Center(child: CircularProgressIndicator(color: AppColors.coral)),
      );
    }
    final userId = user.uid;
    final profile = ref.watch(userProfileProvider(userId)).asData?.value;
    final classes = ref.watch(myClassesProvider(userId));
    final isDesktop = context.screenType == ScreenType.desktop;
    final displayName = _displayName(profile?.name, user.email);

    return AppResponsiveScaffold(
      maxWidth: AppLayout.dashboardMaxWidth,
      appBar: _HomeHeader(
        userId: userId,
        onSearchPressed: () => showHomeSearchSheet(context, userId: userId),
      ),
      body: RefreshIndicator(
        color: AppColors.coral,
        onRefresh: () async {
          ref.invalidate(myClassesProvider(userId));
          await ref.read(myClassesProvider(userId).future);
        },
        child: AppPageBody(
          physics: const AlwaysScrollableScrollPhysics(),
          top: 36,
          bottom: 48,
          children: [
            _Greeting(displayName: displayName),
            classes.when(
              loading:
                  () => const SizedBox(
                    height: 320,
                    child: Center(
                      child: CircularProgressIndicator(color: AppColors.coral),
                    ),
                  ),
              error:
                  (_, _) => _LoadError(
                    onRetry: () => ref.invalidate(myClassesProvider(userId)),
                  ),
              data:
                  (items) => Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (items.isNotEmpty) ...[
                        const SizedBox(height: 32),
                        _SummaryCard(
                          userId: userId,
                          role: profile?.role,
                          classes: items,
                        ),
                      ],
                      const SizedBox(height: 36),
                      _ClassSectionHeader(
                        classCount: items.length,
                        onAddPressed: () => showClassAddSheet(context),
                      ),
                      const SizedBox(height: 24),
                      if (items.isEmpty)
                        _EmptyClassState(
                          onAddPressed: () => showClassAddSheet(context),
                        )
                      else
                        _ClassGrid(classes: items),
                    ],
                  ),
            ),
          ],
        ),
      ),
      bottomNavigationBar:
          isDesktop ? null : const HomeBottomNav(selected: HomeTab.home),
    );
  }

  static String _displayName(String? profileName, String? email) {
    final name = profileName?.trim();
    if (name != null && name.isNotEmpty) return name;
    final localPart = email?.split('@').first.trim() ?? '';
    return localPart.isEmpty ? '학습자' : localPart;
  }
}

class _HomeHeader extends StatelessWidget implements PreferredSizeWidget {
  const _HomeHeader({required this.userId, required this.onSearchPressed});

  final String userId;
  final VoidCallback onSearchPressed;

  @override
  Size get preferredSize => const Size.fromHeight(AppLayout.topBarHeight);

  @override
  Widget build(BuildContext context) {
    final compact = context.screenType == ScreenType.mobile;
    return AppTopBar(
      showBrand: false,
      leading: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          InkWell(
            borderRadius: BorderRadius.circular(8),
            onTap: () => context.go(AppRoutes.home),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 5),
              child: Text(
                'Tugether',
                style: TextStyle(
                  color: AppColors.homeInk,
                  fontSize: compact ? 18 : 20,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.5,
                ),
              ),
            ),
          ),
          if (!compact) ...[
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: AppColors.homeCream,
                borderRadius: BorderRadius.circular(999),
              ),
              child: const Text(
                '아카이브',
                style: TextStyle(
                  color: AppColors.homeBrown,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ],
      ),
      title: compact ? null : const Text('내 클래스'),
      actions: [
        _BellButton(userId: userId),
        _AssetIconButton(
          asset: '$_assetRoot/search.svg',
          tooltip: '검색',
          onPressed: onSearchPressed,
        ),
        const SizedBox(width: 6),
        // The avatar opens 마이 directly; logout lives there.
        Semantics(
          button: true,
          label: '마이',
          child: Tooltip(
            message: '마이',
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: () => context.go(AppRoutes.my),
              child: Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: AppColors.border.withValues(alpha: .8),
                    width: 2,
                  ),
                ),
                child: const CircleAvatar(
                  radius: 18,
                  backgroundColor: AppColors.homePeach,
                  backgroundImage: AssetImage('$_assetRoot/profile.png'),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Bell with the unread count; opens the notification sheet.
class _BellButton extends ConsumerWidget {
  const _BellButton({required this.userId});

  final String userId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final unread = ref.watch(unreadNotificationCountProvider(userId));
    return Stack(
      clipBehavior: Clip.none,
      children: [
        _AssetIconButton(
          asset: '$_assetRoot/bell.svg',
          tooltip: '알림',
          onPressed: () => showNotificationSheet(context, userId: userId),
        ),
        if (unread > 0)
          Positioned(
            right: 2,
            top: 2,
            child: IgnorePointer(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 5),
                constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppColors.coral,
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: AppColors.background, width: 2),
                ),
                child: Text(
                  unread > 99 ? '99+' : '$unread',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    height: 1,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _AssetIconButton extends StatelessWidget {
  const _AssetIconButton({
    required this.asset,
    required this.tooltip,
    required this.onPressed,
  });

  final String asset;
  final String tooltip;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => IconButton(
    tooltip: tooltip,
    visualDensity: VisualDensity.compact,
    onPressed: onPressed,
    icon: SvgPicture.asset(asset, width: 19, height: 19),
  );
}

class _Greeting extends StatelessWidget {
  const _Greeting({required this.displayName});

  final String displayName;

  @override
  Widget build(BuildContext context) {
    final compact = context.screenType == ScreenType.mobile;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '안녕하세요, $displayName님 👋',
          style: TextStyle(
            color: AppColors.homeInk,
            fontSize: compact ? 26 : 30,
            height: 1.3,
            fontWeight: FontWeight.w600,
            letterSpacing: -0.75,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          '오늘은 어떤 공부를 이어갈까요?',
          style: TextStyle(
            color: AppColors.homeMuted,
            fontSize: compact ? 15 : 17,
            height: 1.6,
          ),
        ),
      ],
    );
  }
}

/// "오늘의 요약": two live numbers. Students see today's solved quizzes and
/// the reviews still pending; tutors see drafts and this week's publishes.
class _SummaryCard extends ConsumerWidget {
  const _SummaryCard({
    required this.userId,
    required this.role,
    required this.classes,
  });

  final String userId;
  final UserRole? role;
  final List<StudyClass> classes;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final now = ref.watch(homeClockProvider)();
    final tiles =
        role == UserRole.tutor
            ? _tutorTiles(ref, now)
            : _studentTiles(context, ref, now);
    final compact = context.screenType == ScreenType.mobile;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: AppColors.homeDivider),
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: Color(0x08211B19),
            blurRadius: 12,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child:
          compact
              ? Column(
                children: [
                  tiles[0],
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 10),
                    child: Divider(height: 1, color: AppColors.homeDivider),
                  ),
                  tiles[1],
                ],
              )
              : Row(
                children: [
                  Expanded(child: tiles[0]),
                  const SizedBox(
                    height: 40,
                    child: VerticalDivider(color: AppColors.homeDivider),
                  ),
                  const SizedBox(width: 16),
                  Expanded(child: tiles[1]),
                ],
              ),
    );
  }

  List<Widget> _studentTiles(
    BuildContext context,
    WidgetRef ref,
    DateTime now,
  ) {
    final attempts = ref.watch(quizAttemptsProvider(userId)).asData?.value;
    final reviews = ref.watch(myReviewsProvider(userId)).asData?.value;
    final solved =
        attempts == null
            ? null
            : quizzesSolvedOn(now, attempts.cast<QuizAttempt>());
    final pending =
        reviews == null ? null : pendingReviewCount(reviews.cast<ReviewItem>());
    final target =
        reviews == null ? null : classWithMostPendingReviews(reviews);
    return [
      _SummaryTile(
        iconAsset: '$_assetRoot/focus.svg',
        label: '오늘 푼 퀴즈',
        value: solved == null ? '–' : '$solved개',
      ),
      _SummaryTile(
        iconAsset: '$_assetRoot/study.svg',
        label: '남은 복습',
        value: pending == null ? '–' : '$pending개',
        onTap:
            target == null
                ? null
                : () => context.push(AppRoutes.classReview(target)),
      ),
    ];
  }

  List<Widget> _tutorTiles(WidgetRef ref, DateTime now) {
    var loading = false;
    final notes = <StudyNote>[];
    for (final studyClass in classes) {
      final value = ref.watch(allNotesProvider(studyClass.id));
      if (value.hasValue) {
        notes.addAll(value.value!);
      } else {
        loading = true;
      }
    }
    return [
      _SummaryTile(
        iconAsset: '$_assetRoot/focus.svg',
        label: '작성 중 노트',
        value: loading ? '–' : '${draftNoteCount(notes)}개',
      ),
      _SummaryTile(
        iconAsset: '$_assetRoot/study.svg',
        label: '이번 주 게시',
        value: loading ? '–' : '${notesPublishedThisWeek(now, notes)}개',
      ),
    ];
  }
}

class _SummaryTile extends StatelessWidget {
  const _SummaryTile({
    required this.iconAsset,
    required this.label,
    required this.value,
    this.onTap,
  });

  final String iconAsset;
  final String label;
  final String value;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final row = Row(
      children: [
        Container(
          width: 40,
          height: 40,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: AppColors.homeSage,
            borderRadius: BorderRadius.circular(12),
          ),
          child: SvgPicture.asset(
            iconAsset,
            width: 18,
            height: 18,
            colorFilter: const ColorFilter.mode(
              AppColors.homeSageDark,
              BlendMode.srcIn,
            ),
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  color: AppColors.homeSageDark,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  letterSpacing: .3,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  color: AppColors.homeInk,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        if (onTap != null)
          const Icon(Icons.chevron_right, size: 18, color: AppColors.textFaint),
      ],
    );
    if (onTap == null) {
      return Padding(padding: const EdgeInsets.all(4), child: row);
    }
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(padding: const EdgeInsets.all(4), child: row),
    );
  }
}

class _ClassSectionHeader extends StatelessWidget {
  const _ClassSectionHeader({
    required this.classCount,
    required this.onAddPressed,
  });

  final int classCount;
  final VoidCallback onAddPressed;

  @override
  Widget build(BuildContext context) {
    final empty = classCount == 0;
    final button =
        empty
            ? OutlinedButton.icon(
              onPressed: onAddPressed,
              style: OutlinedButton.styleFrom(
                backgroundColor: AppColors.homeCream,
                foregroundColor: AppColors.homeBrown,
                side: const BorderSide(color: AppColors.homeDivider),
                padding: const EdgeInsets.symmetric(
                  horizontal: 17,
                  vertical: 9,
                ),
                minimumSize: const Size(0, 40),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                textStyle: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              icon: const Icon(Icons.add, size: 14),
              label: const Text('클래스 추가'),
            )
            : FilledButton.icon(
              onPressed: onAddPressed,
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.coral,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 10,
                ),
                minimumSize: const Size(0, 40),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                textStyle: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              icon: const Icon(Icons.add, size: 14),
              label: const Text('클래스 추가'),
            );
    final compact = context.screenType == ScreenType.mobile;
    // Wrap, so a narrow phone drops the button under the title instead of
    // overflowing.
    return Wrap(
      alignment: WrapAlignment.spaceBetween,
      crossAxisAlignment: WrapCrossAlignment.center,
      runSpacing: 12,
      spacing: 12,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '내 클래스',
              style: TextStyle(
                color: AppColors.homeInk,
                fontSize: compact ? 22 : 24,
                fontWeight: FontWeight.w600,
                letterSpacing: -0.6,
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
              decoration: BoxDecoration(
                color: AppColors.homeCream,
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                empty ? '0' : '$classCount개 진행 중',
                style: const TextStyle(
                  color: AppColors.homeMuted,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  letterSpacing: .3,
                ),
              ),
            ),
          ],
        ),
        button,
      ],
    );
  }
}

/// Book-cover grid: 1 column on mobile, 2 on tablet, 3 on desktop, with
/// the 새로운 스터디 찾기 card last.
class _ClassGrid extends StatelessWidget {
  const _ClassGrid({required this.classes});

  final List<StudyClass> classes;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      const gap = 24.0;
      final columns = switch (context.screenType) {
        ScreenType.desktop => 3,
        ScreenType.tablet => 2,
        ScreenType.mobile => 1,
      };
      final cardWidth = (constraints.maxWidth - gap * (columns - 1)) / columns;
      return Wrap(
        spacing: gap,
        runSpacing: gap,
        children: [
          for (var index = 0; index < classes.length; index++)
            SizedBox(
              width: cardWidth,
              child: _StudyClassCard(
                key: HomeScreen.classCardKey(classes[index].id),
                studyClass: classes[index],
                index: index,
              ),
            ),
          SizedBox(width: cardWidth, child: const _DiscoverCard()),
        ],
      );
    },
  );
}

/// Cover colours cycle peach → sage → cream like the Figma shelf.
class _CardPalette {
  const _CardPalette(this.background, this.accent, this.stripe);

  final Color background;
  final Color accent;
  final Color stripe;

  static _CardPalette forIndex(int index) => switch (index % 3) {
    0 => _CardPalette(
      AppColors.homePeach,
      AppColors.homeBrown,
      AppColors.homeBrown.withValues(alpha: .2),
    ),
    1 => _CardPalette(
      AppColors.homeSage,
      AppColors.homeSageDark,
      AppColors.homeSageDark.withValues(alpha: .25),
    ),
    _ => _CardPalette(
      AppColors.homeCream,
      AppColors.coralDark,
      AppColors.coral.withValues(alpha: .3),
    ),
  };
}

const _cardHeight = 256.0;

class _StudyClassCard extends ConsumerWidget {
  const _StudyClassCard({
    super.key,
    required this.studyClass,
    required this.index,
  });

  final StudyClass studyClass;
  final int index;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final palette = _CardPalette.forIndex(index);
    final notes =
        ref.watch(publishedNotesProvider(studyClass.id)).asData?.value;
    final latestTitle =
        notes == null ? null : (notes.isEmpty ? '' : notes.first.title);
    return Semantics(
      button: true,
      label: '${studyClass.title} 클래스 열기',
      child: Material(
        color: palette.background,
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: AppColors.border),
        ),
        child: InkWell(
          onTap: () => context.push(AppRoutes.classDetail(studyClass.id)),
          child: SizedBox(
            height: _cardHeight,
            child: Stack(
              children: [
                // Faux book binding on the left edge.
                Positioned(
                  left: 0,
                  top: 0,
                  bottom: 0,
                  child: Container(
                    width: 10,
                    decoration: BoxDecoration(
                      color: palette.stripe,
                      border: Border(
                        right: BorderSide(
                          color: AppColors.border.withValues(alpha: .6),
                        ),
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(34, 20, 16, 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 13,
                              vertical: 5,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: .8),
                              border: Border.all(color: AppColors.border),
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Text(
                              studyClass.category,
                              style: TextStyle(
                                color: palette.accent,
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                letterSpacing: .3,
                              ),
                            ),
                          ),
                          const Spacer(),
                          IconButton(
                            tooltip: '클래스 정보',
                            visualDensity: VisualDensity.compact,
                            onPressed:
                                () => showClassInfoSheet(context, studyClass),
                            icon: SvgPicture.asset(
                              '$_assetRoot/more.svg',
                              width: 14,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        studyClass.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: AppColors.homeInk,
                          fontSize: 24,
                          height: 1.4,
                          fontWeight: FontWeight.w600,
                          letterSpacing: -0.6,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          SvgPicture.asset('$_assetRoot/tutor.svg', width: 11),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              'Tutor · ${studyClass.tutorName}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: AppColors.homeMuted,
                                fontSize: 15,
                                letterSpacing: .2,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const Spacer(),
                      Container(
                        height: 1,
                        color: AppColors.border.withValues(alpha: .7),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          SvgPicture.asset('$_assetRoot/recent.svg', width: 12),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text.rich(
                              TextSpan(
                                style: const TextStyle(
                                  color: AppColors.homeMuted,
                                  fontSize: 13,
                                ),
                                children: [
                                  if (latestTitle == null)
                                    const TextSpan(text: '최근 학습 불러오는 중')
                                  else if (latestTitle.isEmpty)
                                    const TextSpan(text: '아직 게시된 노트가 없어요')
                                  else ...[
                                    const TextSpan(text: '최근 학습: '),
                                    TextSpan(
                                      text: latestTitle,
                                      style: const TextStyle(
                                        color: AppColors.homeInk,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// 새로운 스터디 찾기: dashed card from Figma; the feature itself is a TODO.
class _DiscoverCard extends StatelessWidget {
  const _DiscoverCard();

  @override
  Widget build(BuildContext context) => CustomPaint(
    painter: const DashedBorderPainter(color: AppColors.border, radius: 20),
    child: Material(
      color: Colors.white.withValues(alpha: .7),
      borderRadius: BorderRadius.circular(20),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => _showMessage(context, '스터디 탐색은 준비 중이에요.'),
        child: SizedBox(
          height: _cardHeight,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 28),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 48,
                  height: 48,
                  alignment: Alignment.center,
                  decoration: const BoxDecoration(
                    color: AppColors.homeCream,
                    shape: BoxShape.circle,
                  ),
                  child: SvgPicture.asset(
                    '$_assetRoot/discover.svg',
                    width: 23,
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  '새로운 스터디 찾기',
                  style: TextStyle(
                    color: AppColors.homeInk,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 240),
                  child: const Text(
                    '학부 동기들과 함께하는 아카이브 스터디에 참여해보세요.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: AppColors.homeMuted,
                      fontSize: 13,
                      height: 1.55,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.homeCream,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        '둘러보기',
                        style: TextStyle(
                          color: AppColors.homeBrown,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(width: 4),
                      SvgPicture.asset('$_assetRoot/arrow.svg', width: 10),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}

/// 01_Home_Empty: one tall card with the glyph, copy, CTA and the hint line.
class _EmptyClassState extends StatelessWidget {
  const _EmptyClassState({required this.onAddPressed});

  final VoidCallback onAddPressed;

  @override
  Widget build(BuildContext context) {
    final compact = context.screenType == ScreenType.mobile;
    return Container(
      clipBehavior: Clip.antiAlias,
      constraints: BoxConstraints(minHeight: compact ? 0 : 580),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: .8),
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(24),
        boxShadow: const [
          BoxShadow(
            color: Color(0x08211B19),
            blurRadius: 12,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Stack(
        children: [
          const Positioned(
            top: -48,
            right: -48,
            child: _AmbientGlow(size: 288, color: AppColors.homePeach),
          ),
          const Positioned(
            bottom: -64,
            left: -48,
            child: _AmbientGlow(size: 320, color: AppColors.homeSage),
          ),
          Padding(
            padding: EdgeInsets.symmetric(
              horizontal: compact ? 24 : 36,
              vertical: compact ? 48 : 72,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const _EmptyGlyph(),
                const SizedBox(height: 36),
                const Text(
                  '아직 참여한 클래스가 없어요.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 22,
                    fontWeight: FontWeight.w600,
                    letterSpacing: -0.55,
                  ),
                ),
                const SizedBox(height: 8),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 320),
                  child: const Text(
                    '새로운 클래스를 추가하고 공부를 시작해보세요.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 15,
                      height: 1.6,
                    ),
                  ),
                ),
                const SizedBox(height: 40),
                DecoratedBox(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.coral.withValues(alpha: .45),
                        blurRadius: 24,
                        offset: const Offset(0, 8),
                        spreadRadius: -4,
                      ),
                    ],
                  ),
                  child: FilledButton.icon(
                    onPressed: onAddPressed,
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.coral,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 32,
                        vertical: 16,
                      ),
                      minimumSize: const Size(0, 56),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      textStyle: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    icon: const Icon(Icons.add, size: 16),
                    label: const Text('클래스 추가하기'),
                  ),
                ),
                const SizedBox(height: 48),
                const Divider(height: 1, color: AppColors.homeDivider),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.lightbulb_outline,
                      size: 15,
                      color: AppColors.homeMuted,
                    ),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        '친구와 함께 참여 코드를 입력하거나 새 스터디 아카이브를 열 수 있어요',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: AppColors.homeMuted,
                          fontSize: compact ? 11 : 12,
                          letterSpacing: .3,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AmbientGlow extends StatelessWidget {
  const _AmbientGlow({required this.size, required this.color});

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) => IgnorePointer(
    child: Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [color.withValues(alpha: .55), color.withValues(alpha: 0)],
        ),
      ),
    ),
  );
}

/// Peach rings with the book glyph and a coral "+" badge.
class _EmptyGlyph extends StatelessWidget {
  const _EmptyGlyph();

  @override
  Widget build(BuildContext context) => SizedBox(
    width: 116,
    height: 116,
    child: Stack(
      children: [
        Container(
          width: 112,
          height: 112,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: AppColors.homeCream,
            shape: BoxShape.circle,
            border: Border.all(color: AppColors.border.withValues(alpha: .6)),
            boxShadow: [
              BoxShadow(
                color: AppColors.coralDark.withValues(alpha: .08),
                blurRadius: 24,
                offset: const Offset(0, 8),
                spreadRadius: -4,
              ),
            ],
          ),
          child: Container(
            width: 80,
            height: 80,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.homePeach.withValues(alpha: .5),
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.coral.withValues(alpha: .2)),
            ),
            child: SvgPicture.asset('$_assetRoot/discover.svg', width: 33),
          ),
        ),
        Positioned(
          right: 0,
          bottom: 0,
          child: Container(
            width: 36,
            height: 36,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.coral,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 4),
            ),
            child: const Icon(Icons.add, size: 14, color: Colors.white),
          ),
        ),
      ],
    ),
  );
}

class _LoadError extends StatelessWidget {
  const _LoadError({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 48),
    child: Column(
      children: [
        const Text('클래스를 불러오지 못했어요.'),
        TextButton(onPressed: onRetry, child: const Text('다시 시도')),
      ],
    ),
  );
}

void _showMessage(BuildContext context, String message) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
}
