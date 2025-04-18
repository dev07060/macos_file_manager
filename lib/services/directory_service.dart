import 'package:macos_file_manager/model/directory_node.dart';

class DirectoryService {
  Future<DirectoryNode> loadDirectoryStructure(String rootPath) async {
    return DirectoryNode.fromDirectory(rootPath);
  }
}
