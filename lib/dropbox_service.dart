import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

class DropboxService {
  static final String accessToken = dotenv.env['DROPBOX_KEY'] ?? ''; // Replace with your generated access token

  /// Retrieves account information of the authenticated user.
  Future<void> getAccountInfo() async {
    final uri = Uri.parse('https://api.dropboxapi.com/2/users/get_current_account');
    final response = await http.post(
      uri,
      headers: {
        'Authorization': 'Bearer $accessToken',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      print('Account Info: $data');
    } else {
      throw Exception('Failed to fetch account info: ${response.body}');
    }
  }

  /// Uploads a file to Dropbox and returns a public URL.
  Future<String?> uploadFile(String localFilePath, String dropboxPath) async {
    final file = File(localFilePath);
    if (!file.existsSync()) {
      throw Exception('File does not exist at $localFilePath');
    }

    try {
      // Check if the file is larger than 150MB, if so, upload in chunks
      if (file.lengthSync() > 150 * 1024 * 1024) {
        return await _uploadFileInChunks(file, dropboxPath);
      }

      // Regular upload for smaller files
      final uri = Uri.parse('https://content.dropboxapi.com/2/files/upload');
      final response = await http.post(
        uri,
        headers: {
          'Authorization': 'Bearer $accessToken',
          'Content-Type': 'application/octet-stream',
          'Dropbox-API-Arg': jsonEncode({
            'path': dropboxPath,
            'mode': 'add',
            'autorename': true,
            'mute': false,
          }),
        },
        body: file.readAsBytesSync(),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        print('File uploaded successfully: $data');
        // Now get the shared link for the file
        return await createSharedLink(dropboxPath);
      } else {
        throw Exception('Failed to upload file: ${response.body}');
      }
    } catch (e) {
      print('Error uploading file: $e');
      rethrow;
    }
  }

  /// Handles chunked uploads for large files (larger than 150MB).
  Future<String?> _uploadFileInChunks(File file, String dropboxPath) async {
    const chunkSize = 8 * 1024 * 1024; // 8MB per chunk
    final fileSize = file.lengthSync();
    final fileStream = file.openRead();
    final sessionStartUri = Uri.parse('https://content.dropboxapi.com/2/files/upload_session/start');
    final sessionAppendUri = Uri.parse('https://content.dropboxapi.com/2/files/upload_session/append_v2');
    final sessionFinishUri = Uri.parse('https://content.dropboxapi.com/2/files/upload_session/finish');

    String? sessionId;
    int uploadedBytes = 0;

    final buffer = <int>[];
    await for (final chunk in fileStream) {
      buffer.addAll(chunk);

      if (buffer.length >= chunkSize || uploadedBytes + buffer.length >= fileSize) {
        final chunkToSend = buffer.toList();
        buffer.clear();

        final isStarting = sessionId == null;
        final isFinishing = uploadedBytes + chunkToSend.length >= fileSize;

        final uri = isStarting
            ? sessionStartUri
            : isFinishing
            ? sessionFinishUri
            : sessionAppendUri;

        final headers = {
          'Authorization': 'Bearer $accessToken',
          'Content-Type': 'application/octet-stream',
          'Dropbox-API-Arg': jsonEncode({
            if (!isStarting) 'cursor': {'session_id': sessionId, 'offset': uploadedBytes},
            if (isFinishing) 'commit': {'path': dropboxPath, 'mode': 'add', 'autorename': true, 'mute': false},
          }),
        };

        final response = await http.post(uri, headers: headers, body: chunkToSend);

        if (response.statusCode == 200) {
          if (isStarting) {
            final responseData = jsonDecode(response.body);
            sessionId = responseData['session_id'];
          }
          uploadedBytes += chunkToSend.length;
        } else {
          throw Exception('Failed during upload session: ${response.body}');
        }
      }
    }

    if (sessionId == null) {
      throw Exception('Failed to initialize upload session.');
    }

    print('File uploaded successfully in chunks.');
    // Now get the shared link for the file
    return await createSharedLink(dropboxPath);
  }

  /// Creates a shared link for the uploaded file to get the public URL.
  Future<String?> createSharedLink(String dropboxPath) async {
    final uri = Uri.parse('https://api.dropboxapi.com/2/files/get_temporary_link');
    final response = await http.post(
      uri,
      headers: {
        'Authorization': 'Bearer $accessToken',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'path': dropboxPath,
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final publicUrl = data['link'];
      print('Public URL: $publicUrl');
      return publicUrl; // Return the public URL of the file
    } else {
      throw Exception('Failed to get shared link: ${response.body}');
    }
  }
}