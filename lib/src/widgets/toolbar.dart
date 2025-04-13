part of '../home.dart';

class Toolbar extends HookConsumerWidget with HomeState, HomeEvent {
  const Toolbar({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final history = directoryHistory(ref);
    final currentDir = currentDirectory(ref);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        border: Border(bottom: BorderSide(color: Colors.grey.shade300, width: 1)),
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: history.canGoBack ? () => navigateBack(ref) : null,
            tooltip: 'Back',
          ),
          IconButton(
            icon: const Icon(Icons.arrow_forward),
            onPressed: history.canGoForward ? () => navigateForward(ref) : null,
            tooltip: 'Forward',
          ),
          IconButton(
            icon: const Icon(Icons.arrow_upward),
            onPressed: () => navigateUp(ref),
            tooltip: 'Parent Directory',
          ),
          IconButton(icon: const Icon(Icons.home), onPressed: () => navigateToHome(ref), tooltip: 'Home Directory'),
          const SizedBox(width: 8),
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: Colors.grey.shade400),
              ),
              child: Text(currentDir, style: const TextStyle(fontSize: 14), overflow: TextOverflow.ellipsis),
            ),
          ),
        ],
      ),
    );
  }
}
