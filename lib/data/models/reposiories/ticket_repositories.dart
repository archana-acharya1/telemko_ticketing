class TicketRepository {
  Future<dynamic> createTicket(Map<String, dynamic> ticket) async {
    await Future.delayed(const Duration(seconds: 1));
    return {"success": true, "message": "Dummy ticket created"};
  }
}
