import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:mime/mime.dart';
import 'package:path/path.dart' as path;
import 'package:http_parser/http_parser.dart';

import '../data/api/api_client.dart';
import '../presentation/screens/dashboard/lib/data/local/session_manager.dart';

class TicketService {
  /// Replace these endpoints with the correct backend methods once confirmed
  static const fetchTicketsEndpoint = "/api/method/telemko_support.api.get_tickets";
  static const createTicketEndpoint = "/api/method/telemko_support.api.create_ticket";
  static const uploadFileEndpoint = "/api/method/upload_file";

  /// Fetch tickets
  static Future<List<dynamic>> fetchTickets() async {
    final sid = await SessionManager.getSid(); // ensures SID is loaded
    print("[TicketService] Fetching tickets from $fetchTicketsEndpoint");
    print("[TicketService] Current SID: $sid");

    if (sid == null || sid.isEmpty) {
      print("[TicketService] ERROR: No SID available. Cannot fetch tickets.");
      return [];
    }

    try {
      final res = await ApiClient.get(fetchTicketsEndpoint);
      print("[TicketService] Tickets response received: ${res['message']}");
      final tickets = res['message'] ?? [];
      print("[TicketService] Successfully fetched ${tickets.length} tickets");
      return tickets;
    } catch (e) {
      print("[TicketService] ERROR fetching tickets: $e");
      print("[TicketService] Error type: ${e.runtimeType}");
      return [];
    }
  }

  /// Create a ticket
  static Future<Map<String, dynamic>> createTicket(Map<String, dynamic> body) async {
    await SessionManager.getSid();
    print("[TicketService] Creating ticket with body: $body");

    try {
      final res = await ApiClient.post(createTicketEndpoint, body);
      print("[TicketService] Ticket created: $res");
      return res;
    } catch (e) {
      print("[TicketService] Error creating ticket: $e");
      return {"error": e.toString()};
    }
  }

  /// Upload a file
  static Future<String?> uploadFile({
    required File file,
    required String doctype,
    required String docname,
    bool isPrivate = false,
  }) async {
    await SessionManager.getSid();
    print("[TicketService] Uploading file ${file.path} to $doctype/$docname");

    final uri = Uri.parse(ApiClient.baseUrl + uploadFileEndpoint);
    final request = http.MultipartRequest("POST", uri);

    if (ApiClient.sid != null) {
      request.headers['Cookie'] = "sid=${ApiClient.sid}";
    }

    request.fields['attached_to_doctype'] = doctype;
    request.fields['attached_to_name'] = docname;
    request.fields['is_private'] = isPrivate ? '1' : '0';

    final mimeType = lookupMimeType(file.path) ?? 'application/octet-stream';
    final parts = mimeType.split('/');
    request.files.add(await http.MultipartFile.fromPath(
      'file',
      file.path,
      filename: path.basename(file.path),
      contentType: MediaType(parts[0], parts[1]),
    ));

    try {
      final streamed = await request.send();
      final response = await http.Response.fromStream(streamed);
      print("[TicketService] Upload response status: ${response.statusCode}, body: ${response.body}");

      if (response.statusCode != 200) {
        print("[TicketService] Upload failed");
        return null;
      }

      final body = jsonDecode(response.body);
      final fileUrl = body["message"]["file_url"];
      print("[TicketService] File uploaded successfully: $fileUrl");
      return fileUrl;
    } catch (e) {
      print("[TicketService] Error uploading file: $e");
      return null;
    }
  }
}
