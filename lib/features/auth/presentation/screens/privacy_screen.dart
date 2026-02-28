import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../widgets/auth_page_scaffold.dart';
import '../widgets/auth_top_bar.dart';

class PrivacyScreen extends StatelessWidget {
  const PrivacyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AuthPageScaffold(
      maxWidth: 896, // max-w-4xl
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      withScrollbar: true,
      scrollPhysics: const AlwaysScrollableScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
                      AuthTopBar(
                        leftChildren: <Widget>[
                          IconButton(
                            onPressed: () => context.go('/'),
                            tooltip: 'Back to main page',
                            icon: const Icon(
                              Icons.arrow_back_rounded,
                              color: Color(0xFF9F1239),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Privacy Policy',
                        style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF7C2D12), // rose-900
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Last Updated: February 25, 2026',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: const Color(0xFFE11D48), // rose-600
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 24),
                      _buildSection(
                        context,
                        title: '1. Introduction',
                        paragraphs: const <String>[
                          'Drawback ("we," "us," "our," or "Company") operates a real-time collaborative drawing platform. This Privacy Policy explains how we collect, use, disclose, and safeguard your information when you use our service, including our website, mobile application, and related services (collectively, the "Service").',
                          'Please read this Privacy Policy carefully. If you do not agree with our policies and practices, please do not use our Service.',
                        ],
                      ),
                      const SizedBox(height: 24),
                      _buildSection(
                        context,
                        title: '2. Information We Collect',
                        paragraphs: const <String>[
                          'We collect various types of information in connection with the services we provide, including:',
                        ],
                      ),
                      const SizedBox(height: 16),
                      _buildSubsectionTitle(
                        context,
                        title: '2.1 Information You Provide Directly',
                      ),
                      const SizedBox(height: 12),
                      _buildBulletGroup(
                        context,
                        heading: 'Account Registration:',
                        items: const <String>[
                          'Email address (required for account creation and identity verification)',
                          'Display name (used for profile identification and search)',
                          'Password (securely hashed, never stored in plain text)',
                        ],
                      ),
                      _buildBulletGroup(
                        context,
                        heading: 'Profile Information:',
                        items: const <String>[
                          'Display name and profile mode (public or private)',
                          'Account settings and preferences',
                          'User blocks and blocked user lists',
                        ],
                      ),
                      _buildBulletGroup(
                        context,
                        heading: 'Communication:',
                        items: const <String>[
                          'Chat requests and responses',
                          'Drawing sessions and collaborative canvases',
                          'Real-time drawing data (strokes, clears, emotes)',
                          'Session history (saved drawing sessions)',
                        ],
                      ),
                      _buildBulletGroup(
                        context,
                        heading: 'Account Management:',
                        items: const <String>[
                          'Email address confirmation tokens',
                          'Password reset tokens (temporary, single-use)',
                          'Activity logs for account security purposes',
                        ],
                      ),
                      const SizedBox(height: 16),
                      _buildSubsectionTitle(
                        context,
                        title: '2.2 Information Collected Automatically',
                      ),
                      const SizedBox(height: 12),
                      _buildBulletGroup(
                        context,
                        heading: 'Connection and Session Data:',
                        items: const <String>[
                          'IP address',
                          'Device and browser information',
                          'Unique socket identifiers for real-time connection',
                          'Session duration and timestamps',
                          'Authentication tokens (JWT)',
                        ],
                      ),
                      _buildBulletGroup(
                        context,
                        heading: 'Usage Data:',
                        items: const <String>[
                          'Drawing activities and interactions',
                          'Chat request patterns',
                          'Search queries',
                          'User connectivity events (login, logout, disconnection)',
                        ],
                      ),
                      const SizedBox(height: 24),
                      _buildSection(
                        context,
                        title: '3. How We Use Your Information',
                        paragraphs: const <String>[],
                      ),
                      const SizedBox(height: 16),
                      _buildSubsectionWithBullets(
                        context,
                        title: '3.1 Service Delivery',
                        items: const <String>[
                          'Creating and maintaining your account',
                          'Enabling real-time collaborative drawing features',
                          'Processing chat requests and responses',
                          'Delivering email confirmations and notifications',
                          'Saving and retrieving drawing sessions',
                        ],
                      ),
                      _buildSubsectionWithBullets(
                        context,
                        title: '3.2 Security and Fraud Prevention',
                        items: const <String>[
                          'Verifying user identity and ownership',
                          'Detecting and preventing abuse, fraud, and unauthorized access',
                          'Enforcing Terms of Service and other agreements',
                          'Protecting the integrity of the Service',
                        ],
                      ),
                      _buildSubsectionWithBullets(
                        context,
                        title: '3.3 Communication',
                        items: const <String>[
                          'Sending security alerts and account notifications',
                          'Responding to inquiries and support requests',
                          'Notifying you of changes to our Service',
                          'Delivering password reset and email confirmation emails',
                        ],
                      ),
                      _buildSubsectionWithBullets(
                        context,
                        title: '3.4 Service Improvement',
                        items: const <String>[
                          'Analyzing usage patterns and service statistics',
                          'Identifying technical issues and optimizing performance',
                          'Understanding user behavior to enhance features',
                          'Conducting research for Service development',
                        ],
                      ),
                      _buildSubsectionWithBullets(
                        context,
                        title: '3.5 Legal Compliance',
                        items: const <String>[
                          'Complying with legal obligations and court orders',
                          'Protecting legal rights and preventing harm',
                          'Enforcing agreements and policies',
                        ],
                      ),
                      const SizedBox(height: 24),
                      _buildSection(
                        context,
                        title: '4. How We Share Your Information',
                        paragraphs: const <String>[],
                      ),
                      const SizedBox(height: 16),
                      _buildSubsectionTitle(
                        context,
                        title: '4.1 With Other Users',
                      ),
                      const SizedBox(height: 12),
                      _buildBulletGroup(
                        context,
                        heading: 'When You Have a Public Profile:',
                        items: const <String>[
                          'Your display name appears in search results and public user listings',
                          'Other users can find you via the public user search functionality',
                        ],
                      ),
                      _buildBulletGroup(
                        context,
                        heading: 'During Collaborative Drawing:',
                        items: const <String>[
                          'Drawing strokes, clears, and emotes are visible to all participants in the same drawing session',
                          'User presence information (who is in the room) is shared with session participants',
                        ],
                      ),
                      _buildBulletGroup(
                        context,
                        heading: 'Chat Requests:',
                        items: const <String>[
                          'Chat request recipients see your user ID and associated information',
                          'Accepted chat participants can see your real-time drawing activity',
                        ],
                      ),
                      _buildSubsectionWithBullets(
                        context,
                        title: '4.2 When You Block Users',
                        items: const <String>[
                          'You can block other users to prevent them from contacting you or seeing your profile',
                          'Block relationships are maintained privately and are not disclosed',
                        ],
                      ),
                      _buildSubsectionWithBullets(
                        context,
                        title: '4.3 With Service Providers',
                        items: const <String>[
                          'Email Service Provider: Email addresses are shared with our mail service provider (Nodemailer/SMTP) solely for sending transactional emails (confirmations, password resets)',
                          'Cloud Infrastructure: Data may be stored on cloud infrastructure providers',
                        ],
                      ),
                      _buildSubsectionWithBullets(
                        context,
                        title: '4.4 Legal Requirements',
                        items: const <String>[
                          'We may disclose information when required by law, court order, or government request',
                          'We will provide notice of such disclosure unless legally prohibited',
                        ],
                      ),
                      _buildSubsectionWithBullets(
                        context,
                        title: '4.5 Business Transfers',
                        items: const <String>[
                          'If Drawback is acquired, merged, or subject to bankruptcy proceedings, your information may be transferred as part of that transaction',
                          'We will provide notice before your information becomes subject to a different privacy policy',
                        ],
                      ),
                      const SizedBox(height: 24),
                      _buildSection(
                        context,
                        title: '5. Data Security',
                        paragraphs: const <String>[],
                      ),
                      const SizedBox(height: 16),
                      _buildSubsectionWithBullets(
                        context,
                        title: '5.1 Security Measures',
                        items: const <String>[
                          'Passwords are hashed using bcrypt (cost factor 12) before storage',
                          'Sensitive data (passwords, tokens, socket IDs) are excluded from API responses',
                          'JWT tokens are used for stateless authentication',
                          'HTTPS/TLS encryption is used for all data in transit',
                          'Input validation and SQL injection prevention measures are implemented',
                        ],
                      ),
                      _buildSubsectionWithBullets(
                        context,
                        title: '5.2 Limitations',
                        items: const <String>[
                          'While we implement security measures, no system is completely secure',
                          'Unauthorized access, hardware failure, and other factors may compromise security',
                          'You are responsible for maintaining the confidentiality of your login credentials',
                        ],
                      ),
                      const SizedBox(height: 24),
                      _buildSection(
                        context,
                        title: '6. Your Privacy Rights and Choices',
                        paragraphs: const <String>[],
                      ),
                      const SizedBox(height: 16),
                      _buildSubsectionWithBullets(
                        context,
                        title: '6.1 Account Deletion',
                        items: const <String>[
                          'You may delete your account at any time via the Settings section',
                          'Upon deletion, your profile is removed and no longer searchable',
                          'Drawing history and saved sessions associated with your account will be deleted',
                          'This action is permanent and cannot be undone',
                        ],
                      ),
                      _buildSubsectionWithBullets(
                        context,
                        title: '6.2 Profile Visibility',
                        items: const <String>[
                          'You can set your profile to Public (visible in searches) or Private (hidden from public listings)',
                          'Other users cannot search for you when your profile is private, but may send requests if they know your account',
                          'These settings can be changed at any time',
                        ],
                      ),
                      _buildSubsectionWithBullets(
                        context,
                        title: '6.3 User Blocking',
                        items: const <String>[
                          'You can block users to prevent them from contacting you or seeing your profile',
                          'You can unblock users at any time',
                          'A list of your blocked users is available in your account settings',
                        ],
                      ),
                      _buildSubsectionWithBullets(
                        context,
                        title: '6.4 Data Access',
                        items: const <String>[
                          'You can access your personal information through your account profile',
                          'Contact us to request a copy of all data associated with your account',
                        ],
                      ),
                      _buildSubsectionWithBullets(
                        context,
                        title: '6.5 Data Correction',
                        items: const <String>[
                          'You can update your display name and profile settings directly',
                          'Contact us to request corrections to other personal information',
                        ],
                      ),
                      _buildSubsectionWithBullets(
                        context,
                        title: '6.6 Cookie and Tracking Technology',
                        items: const <String>[
                          'We do not use cookies or tracking technologies beyond session management',
                          'You can control browser-level cookies through your browser settings',
                        ],
                      ),
                      const SizedBox(height: 24),
                      _buildSection(
                        context,
                        title: '7. Data Retention',
                        paragraphs: const <String>[],
                      ),
                      const SizedBox(height: 16),
                      _buildSubsectionWithBullets(
                        context,
                        title: '7.1 Active Account Data',
                        items: const <String>[
                          'Personal information and account data are retained while your account is active',
                          'Drawing history and saved sessions are retained until deleted by you or account deletion',
                        ],
                      ),
                      _buildSubsectionWithBullets(
                        context,
                        title: '7.2 After Account Deletion',
                        items: const <String>[
                          'Account information is permanently deleted',
                          'Associated drawing sessions and chat history are removed',
                          'We may retain anonymized usage data for analytics (aggregated, non-identifiable)',
                          'Backup copies may exist for a limited period but will be purged according to our backup retention policy',
                        ],
                      ),
                      _buildSubsectionWithBullets(
                        context,
                        title: '7.3 Legal Requirements',
                        items: const <String>[
                          'We may retain information longer if required by law or for legitimate business purposes',
                        ],
                      ),
                      const SizedBox(height: 24),
                      _buildSection(
                        context,
                        title: '8. Real-Time Communication',
                        paragraphs: const <String>[],
                      ),
                      const SizedBox(height: 16),
                      _buildSubsectionWithBullets(
                        context,
                        title: '8.1 WebSocket Connections',
                        items: const <String>[
                          'Drawing data transmitted via WebSocket connections is not encrypted at the application level (relies on HTTPS/WSS encryption)',
                          'Real-time drawing content is viewable by all participants in a drawing session',
                          'Consider sensitive information before sharing during collaborative sessions',
                        ],
                      ),
                      _buildSubsectionWithBullets(
                        context,
                        title: '8.2 Session Participants',
                        items: const <String>[
                          'When you join a drawing session, your user ID and drawing activity are visible to other participants',
                          'Leaving or disconnecting from a session terminates real-time data sharing',
                        ],
                      ),
                      const SizedBox(height: 24),
                      _buildSection(
                        context,
                        title: '9. Children\'s Privacy',
                        paragraphs: const <String>[
                          'Drawback is not intended for children under 13 years old. We do not knowingly collect personal information from children under 13. If we become aware that we have collected information from a child under 13 without parental consent, we will delete such information promptly. Parents or guardians who believe their child has provided information to Drawback should contact us immediately.',
                        ],
                      ),
                      const SizedBox(height: 24),
                      _buildSection(
                        context,
                        title: '10. International Data Transfers',
                        paragraphs: const <String>[
                          'If you access Drawback from outside the jurisdiction where our servers are located, your information may be transferred to, stored in, and processed in jurisdictions with different data protection laws. By using Drawback, you consent to the transfer of your information to jurisdictions outside your country of residence.',
                        ],
                      ),
                      const SizedBox(height: 24),
                      _buildSection(
                        context,
                        title: '11. Third-Party Links',
                        paragraphs: const <String>[
                          'Drawback may contain links to third-party websites and services not operated by us. This Privacy Policy does not apply to third-party services, and we are not responsible for their privacy practices. We encourage you to review the privacy policies of any third-party service before providing personal information.',
                        ],
                      ),
                      const SizedBox(height: 24),
                      _buildSection(
                        context,
                        title: '12. Do Not Track',
                        paragraphs: const <String>[
                          'Some browsers include a "Do Not Track" feature. Currently, there is no industry standard for recognizing Do Not Track signals. Drawback does not respond to Do Not Track browser signals, but you may disable cookies and limit tracking through your browser settings.',
                        ],
                      ),
                      const SizedBox(height: 24),
                      _buildSection(
                        context,
                        title: '13. California Privacy Rights',
                        paragraphs: const <String>[
                          'For California Residents (CCPA):',
                        ],
                      ),
                      const SizedBox(height: 12),
                      _buildBullets(
                        context,
                        const <String>[
                          'You have the right to know what personal information is collected, used, and shared',
                          'You have the right to delete personal information collected from you',
                          'You have the right to opt-out of the sale or sharing of your personal information',
                          'You have the right to non-discrimination for exercising your privacy rights',
                        ],
                      ),
                      const SizedBox(height: 12),
                      _buildParagraph(
                        context,
                        'To submit a request, contact us using the information in Section 16. We will verify your identity and respond within 45 days.',
                      ),
                      const SizedBox(height: 24),
                      _buildSection(
                        context,
                        title: '14. European Union Privacy Rights',
                        paragraphs: const <String>[
                          'For EU Residents (GDPR):',
                        ],
                      ),
                      const SizedBox(height: 12),
                      _buildBullets(
                        context,
                        const <String>[
                          'You have the right to access, correct, or delete your personal information',
                          'You have the right to restrict processing of your information',
                          'You have the right to data portability',
                          'You have the right to object to processing',
                          'You have the right to lodge a complaint with your supervisory authority',
                        ],
                      ),
                      const SizedBox(height: 12),
                      _buildParagraph(
                        context,
                        'To submit a request, contact us using the information in Section 16. We will respond within 30 days.',
                      ),
                      const SizedBox(height: 24),
                      _buildSection(
                        context,
                        title: '15. Updates to This Privacy Policy',
                        paragraphs: const <String>[
                          'We may update this Privacy Policy from time to time to reflect changes in our practices, technology, applicable laws, or other factors. When we make material changes, we will:',
                        ],
                      ),
                      const SizedBox(height: 12),
                      _buildBullets(
                        context,
                        const <String>[
                          'Update the "Last Updated" date at the top',
                          'Notify you via email or a prominent notice on the Service if the changes significantly affect your rights',
                        ],
                      ),
                      const SizedBox(height: 12),
                      _buildParagraph(
                        context,
                        'Your continued use of Drawback after changes become effective constitutes your acceptance of the updated Privacy Policy.',
                      ),
                      const SizedBox(height: 24),
                      _buildSection(
                        context,
                        title: '16. Contact Us',
                        paragraphs: const <String>[
                          'If you have questions, concerns, or requests regarding this Privacy Policy or our privacy practices, please contact us:',
                        ],
                      ),
                      const SizedBox(height: 12),
                      _buildParagraph(context, 'Email: support@drawback.chat', emphasized: true),
                      const SizedBox(height: 12),
                      _buildParagraph(
                        context,
                        'We will respond to your inquiry within 30 days of receipt.',
                      ),
                      const SizedBox(height: 24),
                      _buildSection(
                        context,
                        title: '17. Additional Information by Jurisdiction',
                        paragraphs: const <String>[],
                      ),
                      const SizedBox(height: 16),
                      _buildSubsectionWithBullets(
                        context,
                        title: '17.1 United Kingdom (GDPR/DPA 2018)',
                        items: const <String>[
                          'You have the same rights as EU residents listed in Section 14.',
                        ],
                      ),
                      _buildSubsectionWithBullets(
                        context,
                        title: '17.2 Canada (PIPEDA)',
                        items: const <String>[
                          'You have the right to access and request correction of your personal information',
                          'You have the right to lodge a complaint with the Office of the Privacy Commissioner of Canada',
                        ],
                      ),
                      _buildSubsectionWithBullets(
                        context,
                        title: '17.3 Australia (Privacy Act 1988)',
                        items: const <String>[
                          'You have the right to request access and correction of your personal information',
                          'You can lodge a complaint with the Office of the Australian Information Commissioner',
                        ],
                      ),
                      const SizedBox(height: 24),
                      _buildSection(
                        context,
                        title: '18. Acknowledgement',
                        paragraphs: const <String>[
                          'By using Drawback, you acknowledge that you have read this Privacy Policy and agree to its terms. If you do not agree, please discontinue your use of the Service.',
                        ],
                      ),
                      const SizedBox(height: 28),
                      Text(
                        'End of Privacy Policy',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF7C2D12),
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],
                  ),
            );
  }

  Widget _buildSection(
    BuildContext context, {
    required String title,
    required List<String> paragraphs,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          title,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
            color: const Color(0xFF7C2D12), // rose-900
          ),
        ),
        if (paragraphs.isNotEmpty) const SizedBox(height: 12),
        ...paragraphs.map((String paragraph) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _buildParagraph(context, paragraph),
            )),
      ],
    );
  }

  Widget _buildSubsectionTitle(
    BuildContext context, {
    required String title,
  }) {
    return Text(
      title,
      style: Theme.of(context).textTheme.titleMedium?.copyWith(
        fontWeight: FontWeight.w700,
        color: const Color(0xFF9F1239), // rose-800
      ),
    );
  }

  Widget _buildSubsectionWithBullets(
    BuildContext context, {
    required String title,
    required List<String> items,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          _buildSubsectionTitle(context, title: title),
          const SizedBox(height: 8),
          _buildBullets(context, items),
        ],
      ),
    );
  }

  Widget _buildBulletGroup(
    BuildContext context, {
    required String heading,
    required List<String> items,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            heading,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w700,
              color: const Color(0xFF9F1239),
            ),
          ),
          const SizedBox(height: 6),
          _buildBullets(context, items),
        ],
      ),
    );
  }

  Widget _buildBullets(BuildContext context, List<String> items) {
    return Padding(
      padding: const EdgeInsets.only(left: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: items
            .map(
              (String item) => Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    const Padding(
                      padding: EdgeInsets.only(top: 2),
                      child: Text('• ', style: TextStyle(fontSize: 13)),
                    ),
                    Expanded(
                      child: Text(
                        item,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: const Color(0xFF9F1239), // rose-800
                          height: 1.35,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            )
            .toList(),
      ),
    );
  }

  Widget _buildParagraph(
    BuildContext context,
    String text, {
    bool emphasized = false,
  }) {
    return Text(
      text,
      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
        color: const Color(0xFF9F1239), // rose-800
        height: 1.4,
        fontWeight: emphasized ? FontWeight.w700 : FontWeight.w400,
      ),
    );
  }
}
