// // lib/test_api_screen.dart
// import 'package:flutter/material.dart';
// import 'services/issue_service.dart';
//
// class TestApiScreen extends StatefulWidget {
//   const TestApiScreen({super.key});
//   @override
//   State<TestApiScreen> createState() => _TestApiScreenState();
// }
//
// class _TestApiScreenState extends State<TestApiScreen> {
//   String output = "Press buttons";
//
//   Future<void> testFetch() async {
//     try {
//       final issues = await IssueService.fetchIssues(mobile: "9852062767");
//       setState(() => output = issues.toString());
//     } catch (e) {
//       setState(() => output = "Error: $e");
//     }
//   }
//
//   Future<void> testCreate() async {
//     try {
//       final data = {
//         "customer": "Demo Customer",
//         "subject": "Demo from app",
//         "custom_mobile_number": "9800000000",
//         "issue_type": "GPS",
//         "custom_issue": "Demo issue created via app"
//       };
//
//       final resp = await IssueService.createIssue(data);
//       setState(() => output = resp.toString());
//     } catch (e) {
//       setState(() => output = "Create error: $e");
//     }
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(title: const Text("API Test")),
//       body: Padding(
//         padding: const EdgeInsets.all(12),
//         child: Column(
//           children: [
//             ElevatedButton(onPressed: testFetch, child: const Text("Fetch Issues")),
//             const SizedBox(height: 8),
//             ElevatedButton(onPressed: testCreate, child: const Text("Create Issue")),
//             const SizedBox(height: 12),
//             Expanded(child: SingleChildScrollView(child: Text(output))),
//           ],
//         ),
//       ),
//     );
//   }
// }
