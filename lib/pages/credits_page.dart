import 'package:flutter/material.dart';

class CreditsPage extends StatelessWidget {
  const CreditsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        title: const Text("C R E D I T S"),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // App Logo and Name
              Center(
                child: Column(
                  children: [
                    Image.asset(
                      'assets/images/Spatiplay_icon.png',
                      height: 100,
                      width: 100,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'S P A T I P L A Y',
                      style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              // Development Credits
              _buildSection(
                context,
                title: 'Development',
                children: [
                  
                  _buildCreditItem(
                    name: 'James Harold B. Aguilar',
                    role: 'Lead Developer',
                    description: 'Full-stack development and architecture',
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // Design Credits
              _buildSection(
                context,
                title: 'Design',
                children: [
                  _buildCreditItem(
                    name: 'Dennis Vidanes',
                    role: 'UI/UX Designer',
                    description: 'App interface and user experience design',
                  ),
                ],
              ),

              // Documentation Credits
              _buildSection(
                context,
                title: 'Documentation',
                children: [
                  _buildCreditItem(
                    name: 'Rencent Claud',
                    role: 'Documentation',
                    description: 'Creates the documentation of the project',
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // Music Credits
              _buildSection(
                context,
                title: 'Music API used',
                children: [
                  _buildCreditItem(
                    name: 'Audius API',
                    role: 'Music Provider',
                    description: 'Background music and sound effects',
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // Version Info
              Center(
                child: Text(
                  'Version 1.0.0',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSection(
    BuildContext context, {
    required String title,
    required List<Widget> children,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          title.toUpperCase(),
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
        const SizedBox(height: 16),
        Container(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.all(16),
          child: Column(
            children: children.isEmpty
                ? [
                    Center(
                      child: Text(
                        'Add your $title credits here',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ),
                  ]
                : children,
          ),
        ),
      ],
    );
  }

Widget _buildCreditItem({
  required String name,
  required String role,
  required String description,
}) {
  return Padding(
    padding: const EdgeInsets.only(bottom: 16),
    child: Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 300), // You can adjust the max width
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              name,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              role,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              description,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 14,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
}
