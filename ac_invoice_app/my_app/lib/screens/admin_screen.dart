import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../services/admin_api_service.dart';
import 'admin_invoice_detail_screen.dart';

class AdminScreen extends StatefulWidget {
  const AdminScreen({super.key});

  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tab;

  List<AdminUser> _users = [];
  List<AdminInvoiceDetail> _invoices = [];

  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();

    _tab = TabController(length: 2, vsync: this);

    _load();
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    if (mounted) {
      setState(() {
        _loading = true;
        _error = null;
      });
    }

    try {
      final users = await AdminApiService.fetchUsers();
      final invoices = await AdminApiService.fetchAllInvoices();

      if (!mounted) return;

      setState(() {
        _users = users;
        _invoices = invoices;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _loading = false;
        _error =
            'Could not load admin data.\nPlease check your server connection.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6F8),

      // ============================================================
      // PREMIUM ADMIN HEADER
      // ============================================================
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        elevation: 0,
        automaticallyImplyLeading: false,
        toolbarHeight: 76,

        titleSpacing: 20,

        title: Row(
          children: [
            Container(
              width: 46,
              height: 46,

              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.12),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.white.withOpacity(0.12)),
              ),

              child: const Icon(
                Icons.admin_panel_settings_rounded,
                color: Colors.white,
                size: 27,
              ),
            ),

            const SizedBox(width: 13),

            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Admin Dashboard',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 19,
                    fontWeight: FontWeight.w800,
                  ),
                ),

                SizedBox(height: 3),

                Text(
                  'Manage your business',
                  style: TextStyle(color: Colors.white60, fontSize: 11),
                ),
              ],
            ),
          ],
        ),

        actions: [
          IconButton(
            tooltip: 'Refresh',
            onPressed: _loading ? null : _load,
            icon: const Icon(Icons.refresh_rounded, color: Colors.white),
          ),

          const SizedBox(width: 8),
        ],

        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(58),

          child: Container(
            height: 58,

            decoration: const BoxDecoration(
              color: Colors.black,
              border: Border(top: BorderSide(color: Colors.white12, width: 1)),
            ),

            child: TabBar(
              controller: _tab,

              indicatorColor: Colors.white,
              indicatorWeight: 3,
              indicatorSize: TabBarIndicatorSize.tab,

              labelColor: Colors.white,
              unselectedLabelColor: Colors.white54,

              labelStyle: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),

              unselectedLabelStyle: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),

              tabs: [
                Tab(
                  icon: const Icon(Icons.people_alt_outlined, size: 19),
                  text: 'Users (${_users.length})',
                ),

                Tab(
                  icon: const Icon(Icons.receipt_long_outlined, size: 19),
                  text: 'Invoices (${_invoices.length})',
                ),
              ],
            ),
          ),
        ),
      ),

      // ============================================================
      // BODY
      // ============================================================
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: Colors.black))
          : _error != null
          ? _errorView()
          : RefreshIndicator(
              onRefresh: _load,
              color: Colors.black,

              child: TabBarView(
                controller: _tab,

                children: [_usersTab(), _invoicesTab()],
              ),
            ),
    );
  }

  // ================================================================
  // ERROR VIEW
  // ================================================================

  Widget _errorView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(25),

        child: Column(
          mainAxisSize: MainAxisSize.min,

          children: [
            Container(
              width: 72,
              height: 72,

              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.06),
                shape: BoxShape.circle,
              ),

              child: const Icon(
                Icons.cloud_off_rounded,
                color: Colors.black54,
                size: 32,
              ),
            ),

            const SizedBox(height: 18),

            Text(
              _error!,
              textAlign: TextAlign.center,

              style: const TextStyle(
                fontSize: 14,
                color: Colors.black54,
                height: 1.5,
              ),
            ),

            const SizedBox(height: 20),

            ElevatedButton.icon(
              onPressed: _load,

              icon: const Icon(Icons.refresh_rounded),

              label: const Text('Try Again'),

              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.black,
                foregroundColor: Colors.white,
                elevation: 0,

                padding: const EdgeInsets.symmetric(
                  horizontal: 22,
                  vertical: 13,
                ),

                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(13),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ================================================================
  // USERS TAB
  // ================================================================

  Widget _usersTab() {
    if (_users.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),

        children: [
          SizedBox(height: MediaQuery.of(context).size.height * 0.35),

          const Icon(
            Icons.people_outline_rounded,
            size: 55,
            color: Colors.black26,
          ),

          const SizedBox(height: 15),

          const Center(
            child: Text(
              'No registered users yet',
              style: TextStyle(color: Colors.black54, fontSize: 14),
            ),
          ),
        ],
      );
    }

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),

      padding: const EdgeInsets.fromLTRB(16, 18, 16, 30),

      children: [
        _buildStatsSection(),

        const SizedBox(height: 22),

        Row(
          children: [
            const Text(
              'Registered Users',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
            ),

            const Spacer(),

            Text(
              '${_users.length} total',
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
            ),
          ],
        ),

        const SizedBox(height: 12),

        ...List.generate(
          _users.length,
          (index) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: _userCard(_users[index]),
          ),
        ),
      ],
    );
  }

  // ================================================================
  // STATISTICS
  // ================================================================

  Widget _buildStatsSection() {
    final adminCount = _users.where((u) => u.role == 'admin').length;

    final normalUsers = _users.where((u) => u.role != 'admin').length;

    return Row(
      children: [
        Expanded(
          child: _statCard(
            icon: Icons.people_alt_rounded,
            title: 'Users',
            value: '${_users.length}',
          ),
        ),

        const SizedBox(width: 10),

        Expanded(
          child: _statCard(
            icon: Icons.admin_panel_settings_rounded,
            title: 'Admins',
            value: '$adminCount',
          ),
        ),

        const SizedBox(width: 10),

        Expanded(
          child: _statCard(
            icon: Icons.person_outline_rounded,
            title: 'Members',
            value: '$normalUsers',
          ),
        ),
      ],
    );
  }

  Widget _statCard({
    required IconData icon,
    required String title,
    required String value,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),

      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(17),

        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 14,
            offset: const Offset(0, 5),
          ),
        ],
      ),

      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,

        children: [
          Container(
            width: 34,
            height: 34,

            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.06),
              borderRadius: BorderRadius.circular(10),
            ),

            child: Icon(icon, size: 19, color: Colors.black),
          ),

          const SizedBox(height: 12),

          Text(
            value,

            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
          ),

          const SizedBox(height: 2),

          Text(
            title,

            style: TextStyle(fontSize: 10, color: Colors.grey.shade600),
          ),
        ],
      ),
    );
  }

  // ================================================================
  // USER CARD
  // ================================================================

  Widget _userCard(AdminUser u) {
    final letter = u.name.isNotEmpty ? u.name[0].toUpperCase() : '?';

    final isAdmin = u.role == 'admin';

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),

        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.045),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),

      child: Padding(
        padding: const EdgeInsets.all(15),

        child: Row(
          children: [
            // Avatar
            Container(
              width: 50,
              height: 50,

              decoration: BoxDecoration(
                color: Colors.black,
                borderRadius: BorderRadius.circular(15),
              ),

              child: Center(
                child: Text(
                  letter,

                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),

            const SizedBox(width: 13),

            // Details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,

                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          u.name.isNotEmpty ? u.name : 'Unknown User',

                          overflow: TextOverflow.ellipsis,

                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),

                      if (isAdmin) ...[
                        const SizedBox(width: 7),

                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 7,
                            vertical: 3,
                          ),

                          decoration: BoxDecoration(
                            color: Colors.black,
                            borderRadius: BorderRadius.circular(6),
                          ),

                          child: const Text(
                            'ADMIN',

                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 8,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),

                  const SizedBox(height: 5),

                  Text(
                    u.email,

                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,

                    style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                  ),

                  if (u.phone.isNotEmpty) ...[
                    const SizedBox(height: 3),

                    Text(
                      u.phone,

                      style: TextStyle(
                        color: Colors.grey.shade500,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ],
              ),
            ),

            // Menu
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert_rounded, color: Colors.black54),

              onSelected: (action) => _handleUserAction(action, u),

              itemBuilder: (context) => [
                PopupMenuItem(
                  value: 'toggle_role',

                  child: Row(
                    children: [
                      Icon(
                        isAdmin
                            ? Icons.remove_moderator_outlined
                            : Icons.admin_panel_settings_outlined,
                        size: 19,
                      ),

                      const SizedBox(width: 10),

                      Text(isAdmin ? 'Remove Admin' : 'Make Admin'),
                    ],
                  ),
                ),

                const PopupMenuItem(
                  value: 'delete',

                  child: Row(
                    children: [
                      Icon(
                        Icons.delete_outline_rounded,
                        size: 19,
                        color: Colors.red,
                      ),

                      SizedBox(width: 10),

                      Text('Delete User', style: TextStyle(color: Colors.red)),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ================================================================
  // USER ACTIONS
  // ================================================================

  Future<void> _handleUserAction(String action, AdminUser u) async {
    if (action == 'toggle_role') {
      final newRole = u.role == 'admin' ? 'user' : 'admin';

      final confirmed = await _confirm(
        title: newRole == 'admin'
            ? 'Make ${u.name} an admin?'
            : 'Remove admin from ${u.name}?',

        message: newRole == 'admin'
            ? 'They will be able to see every user and every invoice.'
            : 'They will go back to seeing only their own invoices.',
      );

      if (!confirmed) return;

      final error = await AdminApiService.setUserRole(u.id, newRole);

      if (!mounted) return;

      if (error == null) {
        setState(() {
          u.role = newRole;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              newRole == 'admin'
                  ? '${u.name} is now an admin'
                  : '${u.name} is no longer an admin',
            ),
          ),
        );
      } else {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(error)));
      }
    }

    if (action == 'delete') {
      final confirmed = await _confirm(
        title: 'Delete ${u.name}?',

        message:
            'This permanently removes their account and every invoice they created. This cannot be undone.',
      );

      if (!confirmed) return;

      final error = await AdminApiService.deleteUser(u.id);

      if (!mounted) return;

      if (error == null) {
        await _load();
      } else {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(error)));
      }
    }
  }

  // ================================================================
  // CONFIRM DIALOG
  // ================================================================

  Future<bool> _confirm({
    required String title,
    required String message,
  }) async {
    final result = await showDialog<bool>(
      context: context,

      builder: (ctx) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(22),
          ),

          title: Text(
            title,

            style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w800),
          ),

          content: Text(
            message,

            style: const TextStyle(color: Colors.black54, height: 1.4),
          ),

          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),

              child: const Text(
                'Cancel',
                style: TextStyle(color: Colors.black54),
              ),
            ),

            ElevatedButton(
              onPressed: () => Navigator.pop(ctx, true),

              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.black,
                foregroundColor: Colors.white,
                elevation: 0,

                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),

              child: const Text('Confirm'),
            ),
          ],
        );
      },
    );

    return result ?? false;
  }

  // ================================================================
  // INVOICES TAB
  // ================================================================

  Widget _invoicesTab() {
    if (_invoices.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),

        children: [
          SizedBox(height: MediaQuery.of(context).size.height * 0.35),

          const Icon(
            Icons.receipt_long_outlined,
            size: 55,
            color: Colors.black26,
          ),

          const SizedBox(height: 15),

          const Center(
            child: Text(
              'No invoices created yet',
              style: TextStyle(color: Colors.black54),
            ),
          ),
        ],
      );
    }

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),

      padding: const EdgeInsets.fromLTRB(16, 18, 16, 30),

      children: [
        // Invoice summary
        _invoiceSummary(),

        const SizedBox(height: 22),

        Row(
          children: [
            const Text(
              'All Invoices',

              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
            ),

            const Spacer(),

            Text(
              '${_invoices.length} invoices',

              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
            ),
          ],
        ),

        const SizedBox(height: 12),

        ...List.generate(
          _invoices.length,
          (index) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: _invoiceCard(_invoices[index]),
          ),
        ),
      ],
    );
  }

  // ================================================================
  // INVOICE SUMMARY
  // ================================================================

  Widget _invoiceSummary() {
    double total = 0;
    double balance = 0;

    for (final invoice in _invoices) {
      total += invoice.total;
      balance += invoice.balance;
    }

    final received = total - balance;

    return Row(
      children: [
        Expanded(
          child: _moneyCard(
            title: 'Total',
            amount: total,
            icon: Icons.account_balance_wallet_outlined,
          ),
        ),

        const SizedBox(width: 10),

        Expanded(
          child: _moneyCard(
            title: 'Received',
            amount: received,
            icon: Icons.check_circle_outline_rounded,
          ),
        ),

        const SizedBox(width: 10),

        Expanded(
          child: _moneyCard(
            title: 'Due',
            amount: balance,
            icon: Icons.pending_actions_rounded,
          ),
        ),
      ],
    );
  }

  Widget _moneyCard({
    required String title,
    required double amount,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),

      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(17),

        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 14,
            offset: const Offset(0, 5),
          ),
        ],
      ),

      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,

        children: [
          Icon(icon, size: 20, color: Colors.black),

          const SizedBox(height: 10),

          Text(
            'Rs. ${amount.toStringAsFixed(0)}',

            maxLines: 1,
            overflow: TextOverflow.ellipsis,

            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
          ),

          const SizedBox(height: 3),

          Text(
            title,

            style: TextStyle(fontSize: 10, color: Colors.grey.shade600),
          ),
        ],
      ),
    );
  }

  // ================================================================
  // INVOICE CARD
  // ================================================================

  Widget _invoiceCard(AdminInvoiceDetail inv) {
    final isPaid = inv.balance <= 0;

    return InkWell(
      borderRadius: BorderRadius.circular(18),

      onTap: () {
        Navigator.push(
          context,

          MaterialPageRoute(
            builder: (_) => AdminInvoiceDetailScreen(invoice: inv),
          ),
        );
      },

      child: Container(
        padding: const EdgeInsets.all(16),

        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),

          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.045),
              blurRadius: 15,
              offset: const Offset(0, 5),
            ),
          ],
        ),

        child: Row(
          children: [
            // Invoice icon
            Container(
              width: 50,
              height: 50,

              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.06),
                borderRadius: BorderRadius.circular(14),
              ),

              child: const Icon(
                Icons.receipt_long_rounded,
                color: Colors.black,
                size: 25,
              ),
            ),

            const SizedBox(width: 13),

            // Details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,

                children: [
                  Text(
                    inv.invoiceNo,

                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                    ),
                  ),

                  const SizedBox(height: 5),

                  Text(
                    inv.createdByName ?? inv.createdByEmail ?? 'Unknown user',

                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,

                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                  ),

                  if (inv.date != null) ...[
                    const SizedBox(height: 3),

                    Text(
                      DateFormat('dd MMM yyyy').format(inv.date!),

                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey.shade500,
                      ),
                    ),
                  ],
                ],
              ),
            ),

            const SizedBox(width: 8),

            // Amount
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,

              children: [
                Text(
                  'Rs. ${inv.total.toStringAsFixed(0)}',

                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                  ),
                ),

                const SizedBox(height: 6),

                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),

                  decoration: BoxDecoration(
                    color: isPaid
                        ? Colors.black.withOpacity(0.07)
                        : Colors.orange.withOpacity(0.10),

                    borderRadius: BorderRadius.circular(7),
                  ),

                  child: Text(
                    isPaid
                        ? 'PAID'
                        : 'DUE Rs. ${inv.balance.toStringAsFixed(0)}',

                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w800,
                      color: isPaid ? Colors.black54 : Colors.orange.shade800,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(width: 5),

            const Icon(Icons.chevron_right_rounded, color: Colors.black26),
          ],
        ),
      ),
    );
  }
}
