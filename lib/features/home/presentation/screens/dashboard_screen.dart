import 'dart:async';

import 'package:flutter/material.dart';

import '../../../../core/realtime/socket_service.dart';
import '../../../../core/services/discovery_access_manager.dart';
import '../../../../core/widgets/status_banner.dart';
import '../../../auth/presentation/auth_controller.dart';
import '../../../discovery/presentation/discovery_controller.dart';
import '../../../discovery/presentation/screens/discovery_game_screen.dart';
import '../../../discovery/presentation/screens/discovery_paywall_screen.dart';
import '../../../discovery/presentation/screens/discovery_swipe_screen.dart';
import '../../../drawing/presentation/screens/chat_room_screen.dart';
import '../../domain/home_models.dart';
import '../home_controller.dart';
import '../widgets/blocked_users_widget.dart';
import '../widgets/chat_requests_widget.dart';
import '../widgets/recent_chats_widget.dart';
import '../widgets/saved_chats_widget.dart';
import '../widgets/user_search_widget.dart';
import 'profile_screen.dart';

enum DashboardView {
  chat,
  profile,
  discoveryPaywall,
  discoveryGame,
  discoverySwipe
}

/// Main dashboard screen with sidebar and content area
class DashboardScreen extends StatefulWidget {
  const DashboardScreen({
    required this.controller,
    required this.authController,
    required this.discoveryController,
    required this.discoveryAccessManager,
    required this.promptPasskeyEnrollment,
    required this.onLogout,
    super.key,
  });

  final HomeController controller;
  final AuthController authController;
  final DiscoveryController discoveryController;
  final DiscoveryAccessManager discoveryAccessManager;
  final bool promptPasskeyEnrollment;
  final VoidCallback onLogout;

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  DashboardView _currentView = DashboardView.chat;
  bool _isSidebarOpen = false;
  bool _hasHandledPasskeyPrompt = false;
  String? _passkeyNotice;
  String? _passkeyError;

  @override
  void initState() {
    super.initState();
    // Load dashboard data and handle post-login prompts once the page is visible.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      widget.controller.loadDashboardData();
      unawaited(_showPasskeyEnrollmentPromptIfNeeded());
    });
  }

  Future<void> _showPasskeyEnrollmentPromptIfNeeded() async {
    if (!widget.promptPasskeyEnrollment || _hasHandledPasskeyPrompt) {
      return;
    }

    // Don't set the flag until we actually show the dialog
    await widget.authController.refreshPasskeyAvailability(notify: false);

    if (!mounted || !widget.authController.canAddPasskey) {
      return;
    }

    if (!widget.authController.isPasskeyAvailable) {
      _hasHandledPasskeyPrompt =
          true; // Set here - we showed the "not available" dialog
      await showDialog<void>(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('Passkey not available'),
            content: const Text(
              'Your account can add a passkey, but this device is not ready for passkeys yet. '
              'Set up screen lock/biometrics (and Google account on Android), then try again.',
            ),
            actions: <Widget>[
              FilledButton(
                onPressed: () => Navigator.of(context).pop(),
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFFBE185D),
                  foregroundColor: const Color(0xFFFCE7F3),
                  padding: const EdgeInsets.all(16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(1),
                  ),
                ),
                child: const Text('OK'),
              ),
            ],
          );
        },
      );
      return;
    }

    _hasHandledPasskeyPrompt =
        true; // Set here - about to show enrollment dialog
    final bool? shouldEnroll = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Add passkey?'),
          content: const Text(
            'Use Face ID, Touch ID, or your device biometrics for faster login next time.',
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              style: TextButton.styleFrom(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(1),
                ),
              ),
              child: const Text('Not now'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFFBE185D),
                foregroundColor: const Color(0xFFFCE7F3),
                padding: const EdgeInsets.all(16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(1),
                ),
              ),
              child: const Text('Add passkey'),
            ),
          ],
        );
      },
    );

    if (shouldEnroll != true || !mounted) {
      return;
    }

    final bool registered =
        await widget.authController.registerPasskeyForCurrentUser();

    if (!mounted) {
      return;
    }

    if (registered) {
      final String message =
          widget.authController.notice ?? 'Passkey added successfully.';
      widget.authController.clearNotice();
      setState(() {
        _passkeyNotice = message;
        _passkeyError = null;
      });
      return;
    }

    final String message = widget.authController.error ??
        'Could not add passkey right now. Please try again.';
    widget.authController.clearError();
    setState(() {
      _passkeyError = message;
      _passkeyNotice = null;
    });
  }

  void _handleChatOpen(String chatRequestId) {
    widget.controller.openChat(chatRequestId);
    setState(() {
      _currentView = DashboardView.chat;
      _isSidebarOpen = false;
    });
  }

  Future<void> _handleDiscoveryGameClick() async {
    SocketService().emitDrawLeave();

    // Refresh current profile state before checking access, so expiration/grace
    // period changes are reflected immediately.
    await widget.controller.loadDashboardData(showLoading: false);

    // Check if user has access (active subscription or temporary ad access)
    final bool hasActiveSubscription =
        widget.controller.profile?.hasDiscoveryAccess ?? false;
    final bool hasAccess =
        widget.discoveryAccessManager.hasAccess(hasActiveSubscription);

    if (!hasAccess) {
      // Show paywall
      setState(() {
        _currentView = DashboardView.discoveryPaywall;
        _isSidebarOpen = false;
      });
      return;
    }

    if (widget.controller.isInDiscoveryGame) {
      // Navigate to discovery swipe screen
      setState(() {
        _currentView = DashboardView.discoverySwipe;
        _isSidebarOpen = false;
      });
    } else {
      // Navigate to discovery game view
      setState(() {
        _currentView = DashboardView.discoveryGame;
        _isSidebarOpen = false;
      });
    }
  }

  Future<void> _handleExitDiscoveryGame() async {
    // Show exit confirmation dialog
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('End Discovery Game'),
          content: const Text(
            'Are you sure you want to end the discovery game? Your drawing will be removed.',
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('No'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFFE11D48),
                padding: const EdgeInsets.all(16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(1),
                ),
              ),
              child: const Text('Yes, end game'),
            ),
          ],
        );
      },
    );

    if (confirmed == true && mounted) {
      await widget.discoveryController.exitDiscoveryGame();
      if (mounted) {
        // Reload dashboard to update status
        await widget.controller.loadDashboardData(showLoading: false);
        // Navigate back to chat view
        setState(() {
          _currentView = DashboardView.chat;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.controller,
      builder: (BuildContext context, _) {
        final String? error = widget.controller.error;
        final String? notice = widget.controller.notice;
        final String? bannerError = _passkeyError ?? error;
        final String? bannerNotice =
            bannerError == null ? (_passkeyNotice ?? notice) : null;

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
            title: Image.asset(
              'assets/images/logo_main.png',
              height: 40,
              fit: BoxFit.contain,
            ),
            actions: <Widget>[
              IconButton(
                icon: const Icon(Icons.person, color: Color(0xFF9F1239)),
                onPressed: () {
                  SocketService().emitDrawLeave();
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
              : SafeArea(
                  child: Column(
                    children: <Widget>[
                      if (bannerError != null || bannerNotice != null)
                        Padding(
                          padding: const EdgeInsets.all(6),
                          child: StatusBanner(
                            key: ValueKey('${bannerError ?? bannerNotice}'),
                            text: bannerError ?? bannerNotice!,
                            kind: bannerError != null
                                ? BannerKind.error
                                : BannerKind.success,
                            onDismiss: () {
                              if (_passkeyError != null ||
                                  _passkeyNotice != null) {
                                setState(() {
                                  _passkeyError = null;
                                  _passkeyNotice = null;
                                });
                              }
                              widget.controller.clearMessages();
                            },
                          ),
                        ),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.all(6),
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
                                          right: BorderSide(
                                              color: Color(0xFFFDA4AF)),
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
                              if (_isSidebarOpen &&
                                  MediaQuery.of(context).size.width < 1024)
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
                              if (_isSidebarOpen &&
                                  MediaQuery.of(context).size.width < 1024)
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

          // Discovery Game Button
          GestureDetector(
            onTap: _handleDiscoveryGameClick,
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: <Color>[
                    Color(0xFFE11D48),
                    Color(0xFFBE123C),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(8),
                boxShadow: const <BoxShadow>[
                  BoxShadow(
                    color: Color(0x40E11D48),
                    blurRadius: 8,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  const Icon(
                    Icons.explore,
                    color: Colors.white,
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      widget.controller.isInDiscoveryGame
                          ? 'In Discovery'
                          : 'Play Discovery',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                      textAlign: TextAlign.left,
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

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
      case DashboardView.discoveryPaywall:
        return DiscoveryPaywallScreen(
          accessManager: widget.discoveryAccessManager,
          onAccessGranted: () {
            // After access is granted, proceed to discovery game or swipe
            if (widget.controller.isInDiscoveryGame) {
              setState(() {
                _currentView = DashboardView.discoverySwipe;
              });
            } else {
              setState(() {
                _currentView = DashboardView.discoveryGame;
              });
            }
          },
          onBack: () {
            setState(() {
              _currentView = DashboardView.chat;
            });
          },
          onProfileRefresh: () async {
            await widget.controller.loadDashboardData(showLoading: false);
            return widget.controller.profile?.hasDiscoveryAccess ?? false;
          },
        );
      case DashboardView.discoveryGame:
        return DiscoveryGameScreen(
          controller: widget.discoveryController,
          onBackToChat: () {
            setState(() {
              _currentView = DashboardView.chat;
            });
            // Reload dashboard to update discovery game status
            widget.controller.loadDashboardData(showLoading: false);
          },
          onNavigateToSwipe: () {
            setState(() {
              _currentView = DashboardView.discoverySwipe;
            });
          },
          onExitGame: _handleExitDiscoveryGame,
        );
      case DashboardView.discoverySwipe:
        return DiscoverySwipeScreen(
          controller: widget.discoveryController,
          accessManager: widget.discoveryAccessManager,
          hasActiveSubscription:
              widget.controller.profile?.hasDiscoveryAccess ?? false,
          onBackToDashboard: () {
            setState(() {
              _currentView = DashboardView.chat;
            });
            // Reload dashboard to update discovery game status
            widget.controller.loadDashboardData(showLoading: false);
          },
          onExitGame: _handleExitDiscoveryGame,
          onAccessExpired: () {
            // Show paywall when temporary access expires
            setState(() {
              _currentView = DashboardView.discoveryPaywall;
            });
          },
          onSendChatRequest: (String displayName) async {
            await widget.controller.sendChatRequest(displayName);
          },
          onAcceptChatRequest: (String chatRequestId) async {
            final bool success = await widget.controller.respondToChatRequest(
              chatRequestId: chatRequestId,
              accept: true,
            );
            if (success) {
              // Reload dashboard to refresh chat state before opening
              await widget.controller.loadDashboardData(showLoading: false);
            }
            return success;
          },
          onOpenChat: (String chatRequestId) {
            _handleChatOpen(chatRequestId);
          },
          connectedUserIds: widget.controller.connectedUserIds,
          pendingOutgoingUserIds: widget.controller.pendingOutgoingUserIds,
          acceptedChatByUserId: widget.controller.acceptedChatByUserId,
          incomingChatRequests: widget.controller.incomingChatRequests,
        );
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

        final ChatRequest? selectedChat = widget.controller.recentChats
            .where((ChatRequest chat) =>
                chat.id == widget.controller.selectedChatRequestId)
            .firstOrNull;

        if (selectedChat == null) {
          // Inconsistent state - reload dashboard to sync
          WidgetsBinding.instance.addPostFrameCallback((_) {
            widget.controller.closeChat();
            widget.controller.loadDashboardData(showLoading: false);
          });
          return const Center(
            child: CircularProgressIndicator(),
          );
        }

        // Check if chat is already saved
        final bool isChatSaved = widget.controller.savedChats
            .any((SavedChat saved) => saved.chatRequestId == selectedChat.id);

        return ChatRoomScreen(
          key: ValueKey(widget.controller.selectedChatRequestId!),
          chatRequestId: widget.controller.selectedChatRequestId!,
          chatRequest: selectedChat,
          profile: widget.controller.profile!,
          isChatSaved: isChatSaved,
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
          onCloseChat: () {
            // Close the chat when socket error "Not in a room" occurs
            widget.controller.closeChat();
          },
          onSubmitReport: ({
            required String reportedUserId,
            required ReportType reportType,
            required String description,
            String? chatRequestId,
            String? sessionContext,
          }) async {
            final bool success = await widget.controller.submitReport(
              reportedUserId: reportedUserId,
              reportType: reportType,
              description: description,
              chatRequestId: chatRequestId,
              sessionContext: sessionContext,
            );

            if (!mounted) {
              return success;
            }

            if (success) {
              final String successMessage = widget.controller.notice ??
                  'Report submitted. Thank you for helping keep Drawback safe.';
              widget.controller.clearNotice();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(successMessage),
                  backgroundColor: Colors.green,
                ),
              );
              return true;
            }

            final String errorMessage = widget.controller.error ??
                'Unable to submit report. Please try again.';
            widget.controller.clearError();
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(errorMessage),
                backgroundColor: Colors.red,
              ),
            );
            return false;
          },
          onSaveChat: () async {
            final bool success = await widget.controller
                .saveChat(widget.controller.selectedChatRequestId!);
            if (success && mounted) {
              widget.controller.loadDashboardData(showLoading: false);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Chat saved.'),
                  backgroundColor: Colors.green,
                ),
              );
            }
          },
        );
    }
  }
}
