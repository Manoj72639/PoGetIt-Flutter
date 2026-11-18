import 'package:flutter/material.dart';

import '../models/master_quest.dart';
import '../services/master_quest_catalog_service.dart';
import '../services/quest_recommendation_service.dart';
import '../theme/pogetit_theme.dart';
import '../widgets/current_location_header.dart';
import 'cafe_attempt_events_screen.dart';
import 'recommended_quests_screen.dart';
import 'quest_direct_open.dart';
import 'profile_screen.dart';

/// Presentation-only dashboard. Existing quest screens remain responsible
/// for execution, validation, evidence, and persistence.
class PoGetItDashboardScreen extends StatefulWidget {
  const PoGetItDashboardScreen({super.key});

  @override
  State<PoGetItDashboardScreen> createState() => _PoGetItDashboardScreenState();
}

class _PoGetItDashboardScreenState extends State<PoGetItDashboardScreen> {
  int _tab = 0;

  @override
  Widget build(BuildContext context) {
    final pages = <Widget>[
      const _TodayPage(),
      const _ExplorePage(),
      const _JourneyPage(),
      const ProfileScreen(),
    ];
    return Scaffold(
      body: IndexedStack(index: _tab, children: pages),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _tab,
        onDestinationSelected: (value) => setState(() => _tab = value),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Today',
          ),
          NavigationDestination(
            icon: Icon(Icons.explore_outlined),
            selectedIcon: Icon(Icons.explore),
            label: 'Explore',
          ),
          NavigationDestination(
            icon: Icon(Icons.bar_chart_outlined),
            selectedIcon: Icon(Icons.bar_chart),
            label: 'Journey',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}

void _open(BuildContext context, Widget screen) {
  Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => screen));
}

class _PageHeader extends StatelessWidget {
  const _PageHeader(this.title, this.subtitle);
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(20, 24, 20, 16),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w800,
            color: PoGetItTheme.black,
          ),
        ),
        const SizedBox(height: 5),
        Text(subtitle, style: const TextStyle(color: PoGetItTheme.gray)),
      ],
    ),
  );
}

class _QuestTile extends StatelessWidget {
  const _QuestTile({required this.quest, required this.onTap});
  final MasterQuest quest;
  final VoidCallback onTap;

  IconData get icon => switch (quest.category) {
    MasterQuestCategory.walkingJogging => Icons.directions_walk,
    MasterQuestCategory.cafeExploration => Icons.local_cafe_outlined,
    MasterQuestCategory.photography => Icons.photo_camera_outlined,
    MasterQuestCategory.reset => Icons.self_improvement,
  };

  @override
  Widget build(BuildContext context) => Card(
    margin: const EdgeInsets.only(bottom: 10),
    child: InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: PoGetItTheme.canvas,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: PoGetItTheme.black),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    quest.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    '${quest.difficulty} · ${quest.estimatedMinutes} min · ${quest.id}',
                    style: const TextStyle(
                      color: PoGetItTheme.gray,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right),
          ],
        ),
      ),
    ),
  );
}

class _TodayPage extends StatefulWidget {
  const _TodayPage();

  @override
  State<_TodayPage> createState() => _TodayPageState();
}

class _TodayPageState extends State<_TodayPage> {
  final _recommendationService = QuestRecommendationService();
  late Future<List<MasterQuest>> _future;

  @override
  void initState() {
    super.initState();
    _future = _recommendationService.recommend();
  }

  void _refresh() => setState(() {
    _future = _recommendationService.recommend();
  });

  @override
  Widget build(BuildContext context) => SafeArea(
    child: RefreshIndicator(
      onRefresh: () async {
        _refresh();
        await _future;
      },
      child: ListView(
        padding: const EdgeInsets.only(bottom: 24),
        children: [
          const _PageHeader('PoGetIt', 'Your next adventure starts here.'),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Card(child: CurrentLocationHeader()),
          ),
          const Padding(
            padding: EdgeInsets.fromLTRB(20, 22, 20, 10),
            child: Text(
              'Recommended for you',
              style: TextStyle(fontSize: 19, fontWeight: FontWeight.w800),
            ),
          ),
          FutureBuilder<List<MasterQuest>>(
            future: _future,
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                if (snapshot.hasError) {
                  return Padding(
                    padding: const EdgeInsets.all(20),
                    child: Text(
                      'Unable to load recommendations: ${snapshot.error}',
                    ),
                  );
                }
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.all(20),
                    child: CircularProgressIndicator(),
                  ),
                );
              }
              final quests = snapshot.data!;
              if (quests.isEmpty) {
                return const Padding(
                  padding: EdgeInsets.all(20),
                  child: Text('No matching quests yet. Review your interests.'),
                );
              }
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  children: [
                    for (final quest in quests)
                      _QuestTile(
                        quest: quest,
                        onTap: () => openSelectedQuest(context, quest),
                      ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    ),
  );
}

class _ExplorePage extends StatefulWidget {
  const _ExplorePage();

  @override
  State<_ExplorePage> createState() => _ExplorePageState();
}

class _ExplorePageState extends State<_ExplorePage> {
  final _catalog = MasterQuestCatalogService();
  late Future<List<MasterQuest>> _future;
  String _query = '';
  MasterQuestCategory? _category;

  @override
  void initState() {
    super.initState();
    _future = _catalog.loadQuests();
  }

  void _refresh() => setState(() {
    _future = _catalog.loadQuests(refresh: true);
  });

  @override
  Widget build(BuildContext context) => SafeArea(
    child: Column(
      children: [
        const _PageHeader(
          'Explore quests',
          'Discover activities from your quest library.',
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: TextField(
            onChanged: (text) =>
                setState(() => _query = text.trim().toLowerCase()),
            decoration: const InputDecoration(
              hintText: 'Search by title or quest ID',
              prefixIcon: Icon(Icons.search),
            ),
          ),
        ),
        SizedBox(
          height: 60,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            children: [
              _chip('All', null),
              _chip('Move', MasterQuestCategory.walkingJogging),
              _chip('Cafés', MasterQuestCategory.cafeExploration),
              _chip('Photography', MasterQuestCategory.photography),
              _chip('Reset', MasterQuestCategory.reset),
            ],
          ),
        ),
        Expanded(
          child: FutureBuilder<List<MasterQuest>>(
            future: _future,
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                if (snapshot.hasError) {
                  return Center(
                    child: Text('Unable to load library: ${snapshot.error}'),
                  );
                }
                return const Center(child: CircularProgressIndicator());
              }
              final matches = snapshot.data!.where((q) {
                return (_category == null || q.category == _category) &&
                    (q.title.toLowerCase().contains(_query) ||
                        q.id.toLowerCase().contains(_query) ||
                        q.description.toLowerCase().contains(_query));
              }).toList();
              return RefreshIndicator(
                onRefresh: () async {
                  _refresh();
                  await _future;
                },
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Text(
                        '${matches.length} quests',
                        style: const TextStyle(color: PoGetItTheme.gray),
                      ),
                    ),
                    for (final q in matches)
                      _QuestTile(
                        quest: q,
                        onTap: () {
                          openSelectedQuest(context, q);
                        },
                      ),
                    if (matches.isEmpty)
                      const Padding(
                        padding: EdgeInsets.all(24),
                        child: Center(
                          child: Text('No quests match your search.'),
                        ),
                      ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    ),
  );

  Widget _chip(String label, MasterQuestCategory? category) => Padding(
    padding: const EdgeInsets.only(right: 8),
    child: ChoiceChip(
      label: Text(label),
      selected: _category == category,
      selectedColor: PoGetItTheme.black,
      labelStyle: TextStyle(
        color: _category == category ? Colors.white : PoGetItTheme.black,
      ),
      onSelected: (_) => setState(() => _category = category),
    ),
  );
}

class _JourneyPage extends StatelessWidget {
  const _JourneyPage();

  @override
  Widget build(BuildContext context) => SafeArea(
    child: ListView(
      padding: const EdgeInsets.only(bottom: 24),
      children: [
        const _PageHeader('Your journey', 'Your quest activity and progress.'),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.timeline_outlined, size: 32),
                  const SizedBox(height: 12),
                  const Text(
                    'Your progress, in one place',
                    style: TextStyle(fontSize: 19, fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Your existing attempt data remains in its current repositories. '
                    'A combined four-category history and verified totals will be added '
                    'when the repositories are integrated.',
                    style: TextStyle(color: PoGetItTheme.gray),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.history),
                      label: const Text('View Café attempt events'),
                      onPressed: () =>
                          _open(context, const CafeAttemptEventsScreen()),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const Padding(
          padding: EdgeInsets.fromLTRB(20, 20, 20, 8),
          child: Text(
            'Continue your journey',
            style: TextStyle(fontSize: 19, fontWeight: FontWeight.w800),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Card(
            child: ListTile(
              leading: const Icon(Icons.flag_outlined),
              title: const Text('Recommended quests'),
              subtitle: const Text('Discover what to complete next'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => _open(context, const RecommendedQuestsScreen()),
            ),
          ),
        ),
      ],
    ),
  );
}
