import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:googleapis/drive/v3.dart' as drive;
import 'package:http/http.dart' as http;

class GoogleDriveService {
  final drive.DriveApi _driveApi;

  GoogleDriveService(http.Client client) : _driveApi = drive.DriveApi(client);

  /// Finds or creates the "CloudSync Docs" folder in the user's Google Drive root
  Future<String> _getOrCreateAppFolder() async {
    try {
      // Search for the folder by name, mimeType, and ensuring it's not trashed
      final searchResult = await _driveApi.files.list(
        q: "mimeType = 'application/vnd.google-apps.folder' and name = 'CloudSync Docs' and trashed = false",
        $fields: 'files(id)',
      );
      final files = searchResult.files ?? [];
      if (files.isNotEmpty) {
        return files.first.id!;
      }

      // If folder not found, create a new one in the root directory
      final folderMetadata = drive.File()
        ..name = 'CloudSync Docs'
        ..mimeType = 'application/vnd.google-apps.folder';

      final createdFolder = await _driveApi.files.create(folderMetadata);
      if (createdFolder.id == null) {
        throw Exception('Failed to create "CloudSync Docs" folder');
      }
      return createdFolder.id!;
    } catch (e) {
      debugPrint('Error resolving application folder: $e');
      rethrow;
    }
  }

  /// Lists all files stored in the "CloudSync Docs" folder
  Future<List<drive.File>> listFiles() async {
    try {
      final folderId = await _getOrCreateAppFolder();
      final fileList = await _driveApi.files.list(
        q: "'$folderId' in parents and trashed = false",
        $fields: 'files(id, name, mimeType, modifiedTime, size)',
      );
      return fileList.files ?? [];
    } catch (e) {
      debugPrint('Error listing files from Google Drive: $e');
      rethrow;
    }
  }

  /// Creates a new text file inside the "CloudSync Docs" folder
  Future<drive.File> createFile(String name, String content) async {
    try {
      final folderId = await _getOrCreateAppFolder();
      final driveFile = drive.File()
        ..name = name
        ..parents = [folderId]
        ..mimeType = 'text/plain';

      final contentBytes = utf8.encode(content);
      final media = drive.Media(
        Stream.value(contentBytes),
        contentBytes.length,
      );

      final response = await _driveApi.files.create(
        driveFile,
        uploadMedia: media,
      );
      return response;
    } catch (e) {
      debugPrint('Error creating file on Google Drive: $e');
      rethrow;
    }
  }

  /// Overwrites an existing file in the "CloudSync Docs" folder
  Future<drive.File> updateFile(String fileId, String content) async {
    try {
      final driveFile = drive.File(); // We only update the content, keeping metadata same
      final contentBytes = utf8.encode(content);
      final media = drive.Media(
        Stream.value(contentBytes),
        contentBytes.length,
      );

      final response = await _driveApi.files.update(
        driveFile,
        fileId,
        uploadMedia: media,
      );
      return response;
    } catch (e) {
      debugPrint('Error updating file on Google Drive: $e');
      rethrow;
    }
  }

  /// Reads the content of a text file from Google Drive
  Future<String> readFile(String fileId) async {
    try {
      final response = await _driveApi.files.get(
        fileId,
        downloadOptions: drive.DownloadOptions.fullMedia,
      );

      if (response is drive.Media) {
        final List<int> bytes = await response.stream.fold<List<int>>(
          [],
          (prev, elem) => prev..addAll(elem),
        );
        return utf8.decode(bytes);
      }
      throw Exception('Failed to download file: Response is not Media');
    } catch (e) {
      debugPrint('Error reading file from Google Drive: $e');
      rethrow;
    }
  }

  /// Deletes a file from Google Drive
  Future<void> deleteFile(String fileId) async {
    try {
      await _driveApi.files.delete(fileId);
    } catch (e) {
      debugPrint('Error deleting file from Google Drive: $e');
      rethrow;
    }
  }
}
