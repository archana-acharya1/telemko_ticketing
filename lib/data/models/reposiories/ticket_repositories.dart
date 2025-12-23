class TicketRepository {
  Future<dynamic> createTicket(Map<String, dynamic> ticket) async {
    print("[TicketRepository] Creating ticket with data: $ticket");

    final response = {"success": true, "message": "Dummy ticket created"};
    print("[TicketRepository] Ticket creation response: $response");

    return response;
  }
}
