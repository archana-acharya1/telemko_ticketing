import 'dart:convert';
import 'dart:io';
import '../data/api/frappe_api.dart';

class IssueService {
  static Future<Map<String, dynamic>> createIssue(
      Map<String, dynamic> data) async {
    final resp = await FrappeApi.post("/api/resource/Issue", data);
    return resp;
  }

  static Future<bool> uploadAttachment(String issueId, File file) async {
    final url = Uri.parse(
        "http://simtrack.deskgoo.com/api/method/upload_file");

    final req = await HttpClient().postUrl(url);

    req.headers.set("Authorization",
        "token d8194889a199fc4:652a81055dda386");
    req.headers.set("Content-Type", "multipart/form-data");

    final multipart = await _fileToMultipart(file, issueId);
    req.add(multipart);

    final res = await req.close();
    return res.statusCode == 200;
  }

  static Future<List<int>> _fileToMultipart(
      File file, String issueId) async {
    final boundary = "----XYZFORMBOUNDARY";
    final builder = BytesBuilder();

    void write(String s) =>
        builder.add(utf8.encode(s));

    write("--$boundary\r\n");
    write(
        'Content-Disposition: form-data; name="file"; filename="${file.path.split('/').last}"\r\n');
    write("Content-Type: image/jpeg\r\n\r\n");
    builder.add(await file.readAsBytes());
    write("\r\n--$boundary--");

    return builder.toBytes();
  }
}
