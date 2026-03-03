import 'package:flutter/material.dart';

import '../../../../core/widgets/status_banner.dart';
import '../../../drawing/presentation/screens/chat_room_screen.dart';
import '../home_controller.dart';
import '../widgets/blocked_users_widget.dart';
import '../widgets/chat_requests_widget.dart';
import '../widgets/recent_chats_widget.dart';
import '../widgets/saved_chats_widget.dart';
import '../widgets/user_search_widget.dart';
import 'profile_screen.dart';

enum DashboardView { chat, profile }

/// Main dashboard screen with sidebar and content area
class DashboardScreen extends StatefulWidget {
  const DashboardScreen({
    required this.controller,
    required this.onLogout,
    super.key,
  });

  final HomeController controller;
  final VoidCallback onLogout;

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  DashboardView _currentView = DashboardView.chat;
  bool _isSidebarOpen = false;

  @override
  void initState() {
    super.initState();
    // Load dashboard data on init
    WidgetsBinding.instance.addPostFrameCallback((_) {
      widget.controller.loadDashboardData();
    });
  }

  void _handleChatOpen(String chatRequestId) {
    widget.controller.openChat(chatRequestId);
    setState(() {
      _currentView = DashboardView.chat;
      _isSidebarOpen = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.controller,
      builder: (BuildContext context, _) {
        final String? error = widget.controller.error;
        final String? notice = widget.controller.notice;

        return Scaffold(
          backgroundColor: const Color(0xFFFCE7F3),
          appBar: AppBar(
            backgroundColor: const Color(0xFFFDA4AF),
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.menu, color: Color(0xFF9F1239)),
              onPressed: () {
                setState(() {
                  _isSidebarOpen = !_isSidebarOpen;
                });
              },
            ),
            title: Text(
              'DrawkcaB',
              style: TextStyle(
                color: const Color(0xFF9F1239),
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
            actions: <Widget>[
              IconButton(
                icon: const Icon(Icons.person, color: Color(0xFF9F1239)),
                onPressed: () {
                  setState(() {
                    _currentView = DashboardView.profile;
                    _isSidebarOpen = false;
                  });
                },
              ),
              IconButton(
                icon: const Icon(Icons.logout, color: Color(0xFF9F1239)),
                onPressed: widget.onLogout,
              ),
            ],
          ),
          body: widget.controller.isLoadingDashboard
              ? const Center(
                  child: CircularProgressIndicator(),
                )
              : Column(
                  children: <Widget>[
                    if (error != null || notice != null)
                      Padding(
                        padding: const EdgeInsets.all(12),
                        child: StatusBanner(
                          text: error ?? notice!,
                          kind: error != null ? BannerKind.error : BannerKind.success,
                        ),
                      ),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Stack(
                          children: <Widget>[
                            // Main content
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: <Widget>[
                                // Sidebar (visible on larger screens)
                                if (MediaQuery.of(context).size.width >= 1024)
                                  Container(
                                    width: 320,
                                    decoration: const BoxDecoration(
                                      color: Color(0xFFFDA4AF),
                                      border: Border(
                                        right: BorderSide(color: Color(0xFFFDA4AF)),
                                      ),
                                    ),
                                    child: _buildSidebar(),
                                  ),

                                const SizedBox(width: 12),

                                // Content area
                                Expanded(
                                  child: Container(
                                    color: const Color(0xFFFDA4AF),
                                    child: _buildContent(),
                                  ),
                                ),
                              ],
                            ),

                          // Mobile sidebar overlay
                          if (_isSidebarOpen && MediaQuery.of(context).size.width < 1024)
                            GestureDetector(
                              onTap: () {
                                setState(() {
                                  _isSidebarOpen = false;
                                });
                              },
                              child: Container(
                                color: Colors.black54,
                              ),
                            ),

                          // Mobile sidebar
                          if (_isSidebarOpen && MediaQuery.of(context).size.width < 1024)
                            Positioned(
                              left: 0,
                              top: 0,
                              bottom: 0,
                              child: Container(
                                width: 300,
                                decoration: const BoxDecoration(
                                  color: Color(0xFFFDA4AF),
                                  boxShadow: <BoxShadow>[
                                    BoxShadow(
                                      color: Colors.black26,
                                      blurRadius: 10,
                                      offset: Offset(2, 0),
                                    ),
                                  ],
                                ),
                                child: Column(
                                  children: <Widget>[
                                    Container(
                                      padding: const EdgeInsets.all(12),
                                      decoration: const BoxDecoration(
                                        border: Border(
                                          bottom: BorderSide(color: Color(0xFFFDA4AF)),
                                        ),
                                      ),
                                      child: Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: <Widget>[
                                          const Text(
                                            'Menu',
                                            style: TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.w600,
                                              color: Color(0xFF9F1239),
                                            ),
                                          ),
                                          IconButton(
                                            icon: const Icon(
                                              Icons.close,
                                              color: Color(0xFF9F1239),
                                            ),
                                            onPressed: () {
                                              setState(() {
                                                _isSidebarOpen = false;
                                              });
                                            },
                                          ),
                                        ],
                                      ),
                                    ),
                                    Expanded(child: _buildSidebar()),
                                  ],
                                ),
                              ),
                            ),
                        ],
                      ),
                      ),
                    ),
                  ],
                ),
        );
      },
    );
  }

  Widget _buildSidebar() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Text(
            'Welcome ${widget.controller.profile?.displayName ?? ""}',
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Color(0xFF9F1239),
            ),
          ),
          const Divider(height: 24, color: Color(0xFFFDA4AF)),

          UserSearchWidget(
            controller: widget.controller,
            onChatRequest: _handleChatOpen,
          ),

          const SizedBox(height: 16),

          RecentChatsWidget(
            controller: widget.controller,
            onChatOpen: _handleChatOpen,
            selectedChatId: widget.controller.selectedChatRequestId,
          ),

          const SizedBox(height: 16),

          ChatRequestsWidget(controller: widget.controller),

          const SizedBox(height: 16),

          SavedChatsWidget(
            controller: widget.controller,
            onChatOpen: _handleChatOpen,
          ),

          const SizedBox(height: 16),

          BlockedUsersWidget(controller: widget.controller),
        ],
      ),
    );
  }

  Widget _buildContent() {
    switch (_currentView) {
      case DashboardView.profile:
        return ProfileScreen(controller: widget.controller);
      case DashboardView.chat:
        if (widget.controller.selectedChatRequestId == null) {
          return const Center(
            child: Text(
              'Select a chat to start drawing',
              style: TextStyle(color: Color(0xFF9F1239)),
            ),
          );
        }
        
        // Show chat room with drawing canvas
        if (widget.controller.profile == null) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        }

        return ChatRoomScreen(
          chatRequestId: widget.controller.selectedChatRequestId!,
          profile: widget.controller.profile!,
          onNotice: (String message, String type) {
            // Handle notices from chat room
            if (mounted) {
              // You could show a snackbar or update controller error state
              final String noticeType = type == 'error' ? 'Error: ' : '';
              widget.controller.clearMessages();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('$noticeType$message'),
                  backgroundColor: type == 'error'
                      ? Colors.red
                      : type == 'success'
                          ? Colors.green
                          : Colors.blue,
                ),
              );
            }
          },
        );
    }
  }
}
