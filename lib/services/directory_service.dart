import 'package:macos_file_manager/model/directory_node_data.dart';

class DirectoryService {
  Future<DirectoryNodeData> loadDirectoryStructure(String rootPath) async {
    return DirectoryNodeData.fromDirectory(rootPath);
  }
}
