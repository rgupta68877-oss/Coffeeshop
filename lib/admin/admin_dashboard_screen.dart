import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../core/app_colors.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Admin Dashboard'),
          foregroundColor: Colors.white,
          flexibleSpace: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.espresso,
                  AppColors.cocoa,
                  AppColors.caramel,
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),
          bottom: const TabBar(
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            indicatorColor: Colors.white,
            tabs: [
              Tab(text: 'Users'),
              Tab(text: 'Owners'),
              Tab(text: 'Complaints'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _buildUserList(role: 'Customer'),
            _buildUserList(role: 'Owner'),
            _buildComplaints(),
          ],
        ),
      ),
    );
  }

  Widget _buildUserList({required String role}) {
    return StreamBuilder<QuerySnapshot>(
      stream: _firestore
          .collection('users')
          .where('role', isEqualTo: role)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final users = snapshot.data!.docs;
        if (users.isEmpty) {
          return Center(child: Text('No $role accounts found'));
        }
        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: users.length,
          separatorBuilder: (context, index) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            final doc = users[index];
            final data = doc.data() as Map<String, dynamic>;
            final isActive = data['isActive'] ?? true;
            return Card(
              child: ListTile(
                title: Text(data['name'] ?? 'Unnamed'),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(data['email'] ?? ''),
                    if ((data['phone'] ?? '').toString().isNotEmpty)
                      Text('Phone: ${data['phone']}'),
                  ],
                ),
                trailing: Switch(
                  value: isActive,
                  onChanged: (value) async {
                    await _firestore.collection('users').doc(doc.id).update({
                      'isActive': value,
                    });
                  },
                  activeThumbColor: AppColors.matcha,
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildComplaints() {
    return StreamBuilder<QuerySnapshot>(
      stream: _firestore
          .collection('complaints')
          .orderBy('createdAt', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final complaints = snapshot.data!.docs;
        if (complaints.isEmpty) {
          return const Center(child: Text('No complaints yet'));
        }
        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: complaints.length,
          separatorBuilder: (context, index) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            final doc = complaints[index];
            final data = doc.data() as Map<String, dynamic>;
            final status = data['status'] ?? 'open';
            final priority = (data['priority'] ?? 'medium').toString();
            final slaDeadline = data['slaDeadline'];
            final deadline = slaDeadline is Timestamp
                ? slaDeadline.toDate()
                : null;
            final isOverdue =
                deadline != null &&
                status.toString().toLowerCase() != 'resolved' &&
                DateTime.now().isAfter(deadline);
            final createdAt = data['createdAt'];
            final createdLabel = createdAt is Timestamp
                ? createdAt.toDate().toString()
                : createdAt?.toString() ?? '';
            return Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          data['subject'] ?? 'Complaint',
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.w700),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: status == 'resolved'
                                ? AppColors.matcha.withOpacityValue(0.2)
                                : AppColors.caramel.withOpacityValue(0.2),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            status.toString().toUpperCase(),
                            style: Theme.of(context).textTheme.labelSmall
                                ?.copyWith(
                                  color: status == 'resolved'
                                      ? AppColors.matcha
                                      : AppColors.caramel,
                                  fontWeight: FontWeight.w700,
                                ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 8,
                      runSpacing: 6,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.oat,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            'Priority: ${priority.toUpperCase()}',
                            style: Theme.of(context).textTheme.labelSmall
                                ?.copyWith(
                                  color: AppColors.espresso,
                                  fontWeight: FontWeight.w700,
                                ),
                          ),
                        ),
                        if (deadline != null)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: isOverdue
                                  ? Colors.red.withOpacityValue(0.15)
                                  : AppColors.matcha.withOpacityValue(0.15),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              isOverdue
                                  ? 'SLA OVERDUE'
                                  : 'SLA: ${deadline.toString()}',
                              style: Theme.of(context).textTheme.labelSmall
                                  ?.copyWith(
                                    color: isOverdue
                                        ? Colors.red
                                        : AppColors.matcha,
                                    fontWeight: FontWeight.w700,
                                  ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text('From: ${data['userName'] ?? 'Unknown'}'),
                    Text('Role: ${data['role'] ?? 'Unknown'}'),
                    if ((data['shopId'] ?? '').toString().isNotEmpty)
                      Text('Shop: ${data['shopId']}'),
                    const SizedBox(height: 8),
                    Text(data['message'] ?? ''),
                    const SizedBox(height: 8),
                    Text(
                      createdLabel,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.ink.withOpacityValue(0.6),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Align(
                      alignment: Alignment.centerRight,
                      child: Wrap(
                        spacing: 8,
                        children: [
                          TextButton(
                            onPressed: status == 'open'
                                ? () async {
                                    await _firestore
                                        .collection('complaints')
                                        .doc(doc.id)
                                        .update({'status': 'in_progress'});
                                  }
                                : null,
                            child: const Text('Start Work'),
                          ),
                          TextButton(
                            onPressed: status == 'resolved'
                                ? null
                                : () async {
                                    await _firestore
                                        .collection('complaints')
                                        .doc(doc.id)
                                        .update({
                                          'status': 'resolved',
                                          'resolvedAt':
                                              FieldValue.serverTimestamp(),
                                        });
                                  },
                            child: const Text('Mark Resolved'),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}
