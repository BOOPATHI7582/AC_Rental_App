import 'package:flutter/material.dart';

import '../models/client.dart';
import '../services/storage_service.dart';
import 'client_form_screen.dart';

class ClientsScreen extends StatefulWidget {
  const ClientsScreen({super.key});

  @override
  State<ClientsScreen> createState() => _ClientsScreenState();
}

class _ClientsScreenState extends State<ClientsScreen> {
  List<Client> _clients = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final clients = await StorageService.instance.getClients();
    setState(() {
      _clients = clients;
      _loading = false;
    });
  }

  Future<void> _delete(Client c) async {
    await StorageService.instance.deleteClient(c.id);
    _load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Clients')),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const ClientFormScreen()),
          );
          _load();
        },
        child: const Icon(Icons.add),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: Colors.black))
          : _clients.isEmpty
              ? const Center(
                  child: Text('No clients yet.\nTap + to add your first client.',
                      textAlign: TextAlign.center, style: TextStyle(color: Colors.black54)),
                )
              : ListView.separated(
                  padding: const EdgeInsets.all(12),
                  itemCount: _clients.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, i) {
                    final c = _clients[i];
                    return Dismissible(
                      key: ValueKey(c.id),
                      direction: DismissDirection.endToStart,
                      background: Container(
                        color: Colors.black,
                        alignment: Alignment.centerRight,
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: const Icon(Icons.delete, color: Colors.white),
                      ),
                      confirmDismiss: (_) => _confirmDelete(c),
                      onDismissed: (_) => _delete(c),
                      child: ListTile(
                        title: Text(c.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                        subtitle: Text([c.phone, c.gstin].where((e) => e.isNotEmpty).join(' • ')),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () async {
                          await Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => ClientFormScreen(existing: c)),
                          );
                          _load();
                        },
                      ),
                    );
                  },
                ),
    );
  }

  Future<bool> _confirmDelete(Client c) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete client?'),
        content: Text('This will remove ${c.name} from your client list.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Delete')),
        ],
      ),
    );
    return result ?? false;
  }
}
