import 'package:flutter/material.dart';

import '../services/profile_service.dart';
import '../widgets/current_location_header.dart';

import 'recommended_quests_screen.dart';
import 'profile_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final profileService = ProfileService();

    return Scaffold(
      appBar: AppBar(
        title: const Text('PoGetIt'),
        actions: [
          IconButton(
            tooltip: 'My Profile',
            icon: const Icon(Icons.account_circle_outlined),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute<void>(builder: (_) => const ProfileScreen()),
              );
            },
          ),
        ],
      ),
      body: SafeArea(
        child: StreamBuilder(
          stream: profileService.watchProfile(),
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return Center(
                child: Text('Unable to load profile: ${snapshot.error}'),
              );
            }

            if (!snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }

            final data = snapshot.data!.data();

            if (data == null) {
              return const Center(child: Text('Profile not found'));
            }

            final name = data['name']?.toString().trim() ?? '';

            final interests = (data['interests'] as List<dynamic>? ?? [])
                .map((e) => e.toString())
                .join(', ');

            final activity = data['activityLevel']?.toString() ?? '-';

            final minutes = (data['preferredMinutes'] as num?)?.toInt() ?? 0;

            final target = (data['weeklyTarget'] as num?)?.toInt() ?? 0;

            return ListView(
              padding: const EdgeInsets.only(bottom: 20),
              children: [
                const CurrentLocationHeader(),

                const Divider(height: 1),

                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Hi, ${name.isEmpty ? 'Explorer' : name}',
                        style: const TextStyle(
                          fontSize: 19,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),

                      const SizedBox(height: 10),

                      Card(
                        margin: EdgeInsets.zero,
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Your Profile',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),

                              const Divider(),

                              _infoRow(
                                'Interests',
                                interests.isEmpty ? 'Not selected' : interests,
                              ),
                              _infoRow('Activity', activity),
                              _infoRow('Duration', '$minutes min'),
                              _infoRow('Weekly Goal', '$target quests'),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 12),

                      Card(
                        margin: EdgeInsets.zero,
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Recommended Quests',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 6),
                              const Text(
                                'Quests matched to your '
                                'interests and preferences.',
                                style: TextStyle(fontSize: 13),
                              ),
                              const SizedBox(height: 10),
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton(
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute<void>(
                                        builder: (_) =>
                                            const RecommendedQuestsScreen(),
                                      ),
                                    );
                                  },
                                  child: const Text(
                                    'View Recommended Quests',
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 10),

                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: () {
                            Navigator.pushNamed(context, '/master-quests');
                          },
                          icon: const Icon(Icons.menu_book_outlined),
                          label: const Text('Master Quest Library'),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  static Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 95,
            child: Text(
              label,
              style: const TextStyle(fontSize: 13, color: Colors.grey),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 13),
              softWrap: true,
            ),
          ),
        ],
      ),
    );
  }
}
