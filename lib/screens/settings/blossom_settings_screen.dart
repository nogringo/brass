import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'blossom_settings_controller.dart';
import 'widgets/user_server_item.dart';

class BlossomSettingsScreen extends StatelessWidget {
  const BlossomSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    Get.put(BlossomSettingsController());
    final controller = BlossomSettingsController.to;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Blossom Servers'),
        actions: [
          Obx(
            () => FilledButton(
              onPressed: controller.isSaving.value || !controller.hasChanges
                  ? null
                  : () => controller.saveServerList(),
              child: const Text('Save'),
            ),
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: Obx(
        () => controller.isLoading.value
            ? const Center(child: CircularProgressIndicator())
            : Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Configure your Blossom server list. The first server is the most trusted.',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(
                          context,
                        ).colorScheme.onSurface.withValues(alpha: 0.7),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.surface,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: Theme.of(context).colorScheme.outline,
                            ),
                          ),
                          child: Row(
                            children: [
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                ),
                                child: Icon(
                                  Icons.search,
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onSurfaceVariant,
                                ),
                              ),
                              Expanded(
                                child: TextField(
                                  controller: controller.serverUrlController,
                                  focusNode: controller.searchFocusNode,
                                  decoration: const InputDecoration(
                                    hintText:
                                        'Search servers or enter custom URL',
                                    border: InputBorder.none,
                                    contentPadding: EdgeInsets.symmetric(
                                      vertical: 16,
                                    ),
                                  ),
                                  onSubmitted: (value) =>
                                      controller.addServer(value),
                                ),
                              ),
                              Obx(
                                () => controller.searchQuery.value.isNotEmpty
                                    ? IconButton(
                                        icon: const Icon(Icons.clear, size: 20),
                                        onPressed: () {
                                          controller.serverUrlController
                                              .clear();
                                        },
                                        tooltip: 'Clear',
                                      )
                                    : const SizedBox.shrink(),
                              ),
                              Padding(
                                padding: const EdgeInsets.only(right: 8),
                                child: MouseRegion(
                                  cursor: SystemMouseCursors.click,
                                  child: FilledButton.icon(
                                    onPressed: () {
                                      controller.addServer(
                                        controller.serverUrlController.text,
                                      );
                                      controller.searchFocusNode.unfocus();
                                    },
                                    icon: const Icon(Icons.add, size: 18),
                                    label: const Text('Add'),
                                    style: FilledButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 16,
                                        vertical: 8,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Obx(
                          () =>
                              !controller.isSearchFocused.value ||
                                  controller.filteredSuggestions.isEmpty
                              ? const SizedBox.shrink()
                              : Container(
                                  margin: const EdgeInsets.only(top: 8),
                                  constraints: const BoxConstraints(
                                    maxHeight: 300,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.surfaceContainerHighest,
                                    borderRadius: BorderRadius.circular(12),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withValues(
                                          alpha: 0.1,
                                        ),
                                        blurRadius: 8,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.stretch,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Padding(
                                        padding: const EdgeInsets.fromLTRB(
                                          16,
                                          12,
                                          16,
                                          8,
                                        ),
                                        child: Row(
                                          children: [
                                            Icon(
                                              Icons.recommend,
                                              size: 18,
                                              color: Theme.of(
                                                context,
                                              ).colorScheme.primary,
                                            ),
                                            const SizedBox(width: 8),
                                            Text(
                                              'Suggested Servers (${controller.filteredSuggestions.length})',
                                              style: Theme.of(context)
                                                  .textTheme
                                                  .labelLarge
                                                  ?.copyWith(
                                                    color: Theme.of(context)
                                                        .colorScheme
                                                        .onSurfaceVariant,
                                                  ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      const Divider(height: 1),
                                      Flexible(
                                        child: ListView.builder(
                                          shrinkWrap: true,
                                          padding: const EdgeInsets.symmetric(
                                            vertical: 4,
                                          ),
                                          itemCount: controller
                                              .filteredSuggestions
                                              .length,
                                          itemBuilder: (context, index) {
                                            final server = controller
                                                .filteredSuggestions[index];
                                            return Material(
                                              color: Colors.transparent,
                                              child: InkWell(
                                                onTapDown: (_) {
                                                  controller.addServer(server);
                                                },
                                                child: Padding(
                                                  padding:
                                                      const EdgeInsets.symmetric(
                                                        horizontal: 16,
                                                        vertical: 12,
                                                      ),
                                                  child: Row(
                                                    children: [
                                                      Icon(
                                                        Icons.cloud_outlined,
                                                        size: 20,
                                                        color: Theme.of(context)
                                                            .colorScheme
                                                            .onSurfaceVariant,
                                                      ),
                                                      const SizedBox(width: 12),
                                                      Expanded(
                                                        child: Text(
                                                          server,
                                                          style:
                                                              Theme.of(context)
                                                                  .textTheme
                                                                  .bodyMedium,
                                                        ),
                                                      ),
                                                      Icon(
                                                        Icons
                                                            .add_circle_outline,
                                                        size: 20,
                                                        color: Theme.of(
                                                          context,
                                                        ).colorScheme.primary,
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ),
                                            );
                                          },
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'Servers (${controller.servers.length})',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 12),
                    Expanded(
                      child: Obx(
                        () => controller.servers.isEmpty
                            ? Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.cloud_off,
                                      size: 64,
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onSurface
                                          .withValues(alpha: 0.3),
                                    ),
                                    const SizedBox(height: 16),
                                    Text(
                                      'No servers configured',
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleMedium
                                          ?.copyWith(
                                            color: Theme.of(context)
                                                .colorScheme
                                                .onSurface
                                                .withValues(alpha: 0.5),
                                          ),
                                    ),
                                  ],
                                ),
                              )
                            : ReorderableListView.builder(
                                itemCount: controller.servers.length,
                                onReorder: (oldIndex, newIndex) => controller
                                    .reorderServer(oldIndex, newIndex),
                                itemBuilder: (context, index) {
                                  final server = controller.servers[index];
                                  return UserServerItem(
                                    key: ValueKey(server),
                                    server: server,
                                    index: index,
                                    controller: controller,
                                  );
                                },
                              ),
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}
