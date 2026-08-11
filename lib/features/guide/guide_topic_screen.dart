import 'package:flutter/material.dart';

import '../../core/theme/app_spacing.dart';
import '../../core/widgets/common_widgets.dart';
import 'guide_content.dart';

class GuideTopicScreen extends StatelessWidget {
  const GuideTopicScreen({super.key, required this.topicId});

  final String topicId;

  @override
  Widget build(BuildContext context) {
    final topic = GuideContent.byId(topicId);
    if (topic == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Guia')),
        body: const EmptyState(title: 'Tópico não encontrado'),
      );
    }

    return Scaffold(
      appBar: AppBar(title: Text(topic.title)),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          Text(
            topic.body,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(height: 1.5),
          ),
          const SizedBox(height: AppSpacing.xl),
          AppCard(
            child: Text(
              GuideContent.disclaimer,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
        ],
      ),
    );
  }
}
