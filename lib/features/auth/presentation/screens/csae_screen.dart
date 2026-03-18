import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../widgets/auth_page_scaffold.dart';
import '../widgets/auth_top_bar.dart';

class CsaeScreen extends StatelessWidget {
  const CsaeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AuthPageScaffold(
      maxWidth: 896,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      withScrollbar: true,
      scrollPhysics: const AlwaysScrollableScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          AuthTopBar(
            leftChildren: <Widget>[
              IconButton(
                onPressed: () => context.go('/privacy'),
                tooltip: 'Back to privacy policy',
                icon: const Icon(
                  Icons.arrow_back_rounded,
                  color: Color(0xFF9F1239),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Child Sexual Abuse and Exploitation (CSAE) Standards',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF7C2D12),
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'Last Updated: March 11, 2026',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: const Color(0xFFE11D48),
                  fontWeight: FontWeight.w600,
                ),
          ),
          const SizedBox(height: 24),
          _buildSection(
            context,
            title: '1. Zero Tolerance Policy',
            paragraphs: const <String>[
              'Drawback maintains a zero-tolerance policy regarding child sexual abuse and exploitation (CSAE). Any content or behavior that exploits, endangers, or sexualizes minors is strictly prohibited.',
            ],
          ),
          const SizedBox(height: 16),
          _buildSubsectionWithBullets(
            context,
            title: '1.1 Prohibited Content and Conduct',
            items: const <String>[
              'CSAM, solicitation, or facilitation of child exploitation material',
              'Grooming behavior or attempts to establish inappropriate relationships with minors',
              'Sexualized content involving minors, including cartoon or AI-generated depictions',
              'Sharing links to external sites containing child exploitation content',
            ],
          ),
          const SizedBox(height: 24),
          _buildSection(
            context,
            title: '2. Detection and Prevention',
            paragraphs: const <String>[],
          ),
          const SizedBox(height: 16),
          _buildSubsectionWithBullets(
            context,
            title: '2.1 Proactive Safeguards',
            items: const <String>[
              'Email verification for account registration',
              'Opt-in chat request model before private collaboration',
              'User blocking and profile visibility controls',
              'Safety monitoring and abuse-review workflows',
            ],
          ),
          _buildSubsectionWithBullets(
            context,
            title: '2.2 Technical Measures',
            items: const <String>[
              'Session metadata logging (for security and lawful investigations)',
              'Rate limiting and abuse prevention controls',
              'Secure transport using HTTPS/WSS',
              'Audit trails for moderation and enforcement actions',
            ],
          ),
          const SizedBox(height: 24),
          _buildSection(
            context,
            title: '3. Reporting Mechanisms',
            paragraphs: const <String>[],
          ),
          const SizedBox(height: 16),
          _buildSubsectionWithBullets(
            context,
            title: '3.1 User Reporting',
            items: const <String>[
              'In-app user reporting for safety concerns',
              'Email reporting to safety@drawback.chat or abuse@drawback.chat',
              'Reports reviewed within 24 hours, with CSAE reports prioritized',
            ],
          ),
          _buildSubsectionWithParagraphs(
            context,
            title: '3.2 Anonymous Reporting',
            paragraphs: const <String>[
              'We accept anonymous safety reports. Reporter identity is protected and is never disclosed to the reported user.',
            ],
          ),
          const SizedBox(height: 24),
          _buildSection(
            context,
            title: '4. Investigation and Response',
            paragraphs: const <String>[],
          ),
          const SizedBox(height: 16),
          _buildSubsectionWithNumberedItems(
            context,
            title: '4.1 Investigation Process',
            items: const <String>[
              'Immediate containment and evidence preservation',
              'Safety team review and case triage',
              'Escalation for legal and law-enforcement cooperation when required',
              'Action and documentation with a complete audit trail',
            ],
          ),
          _buildSubsectionWithBullets(
            context,
            title: '4.2 Response Timeline',
            items: const <String>[
              'Urgent CSAE reports are prioritized immediately',
              'Confirmed illegal content is reported according to applicable law',
              'Accounts may be suspended or permanently banned without warning',
            ],
          ),
          const SizedBox(height: 24),
          _buildSection(
            context,
            title: '5. Enforcement Actions',
            paragraphs: const <String>[],
          ),
          const SizedBox(height: 16),
          _buildBullets(
            context,
            const <String>[
              'Immediate account restriction or permanent ban for CSAE violations',
              'Removal of violating content and related access restrictions',
              'Evidence retention for lawful reporting and investigations',
            ],
          ),
          const SizedBox(height: 24),
          _buildSection(
            context,
            title: '6. Cooperation with Law Enforcement',
            paragraphs: const <String>[
              'Drawback cooperates with lawful requests and mandatory reporting obligations, including reporting to NCMEC where applicable.',
            ],
          ),
          const SizedBox(height: 12),
          _buildBullets(
            context,
            const <String>[
              'Secure chain-of-custody and preservation of relevant records',
              'Coordinated disclosure to avoid compromising active investigations',
            ],
          ),
          const SizedBox(height: 24),
          _buildSection(
            context,
            title: '7. Minor Protection',
            paragraphs: const <String>[],
          ),
          const SizedBox(height: 16),
          _buildBullets(
            context,
            const <String>[
              'Drawback is not intended for children under 13',
              'Protective controls for visibility, communication, and moderation',
              'Additional safeguards may be applied for at-risk account activity',
            ],
          ),
          const SizedBox(height: 24),
          _buildSection(
            context,
            title: '8. Staff Training and Access Controls',
            paragraphs: const <String>[],
          ),
          const SizedBox(height: 16),
          _buildBullets(
            context,
            const <String>[
              'Safety personnel receive CSAE response training',
              'Access to sensitive data follows least-privilege principles',
              'Access and moderation actions are logged and auditable',
            ],
          ),
          const SizedBox(height: 24),
          _buildSection(
            context,
            title: '9. Transparency and Accountability',
            paragraphs: const <String>[
              'We continuously review safety operations, improve controls, and maintain internal accountability for response quality.',
            ],
          ),
          const SizedBox(height: 24),
          _buildSection(
            context,
            title: '10. User Education',
            paragraphs: const <String>[
              'Drawback provides guidance on safe usage, suspicious behavior reporting, and emergency resources.',
            ],
          ),
          const SizedBox(height: 12),
          _buildParagraph(
            context,
            'Community guidelines: https://drawback.chat/community-guidelines',
          ),
          const SizedBox(height: 24),
          _buildSection(
            context,
            title: '11. Continuous Improvement',
            paragraphs: const <String>[
              'These standards are reviewed regularly and updated as legal requirements, threat patterns, and platform capabilities evolve.',
            ],
          ),
          const SizedBox(height: 24),
          _buildSection(
            context,
            title: '12. Contact Information',
            paragraphs: const <String>[],
          ),
          const SizedBox(height: 12),
          _buildParagraph(
            context,
            'Safety: safety@drawback.chat',
            emphasized: true,
          ),
          const SizedBox(height: 12),
          _buildParagraph(
            context,
            'Abuse Reports: abuse@drawback.chat',
            emphasized: true,
          ),
          const SizedBox(height: 12),
          _buildParagraph(
            context,
            'Legal/Law Enforcement: legal@drawback.chat',
            emphasized: true,
          ),
          const SizedBox(height: 24),
          _buildSection(
            context,
            title: '13. Emergency Resources',
            paragraphs: const <String>[
              'If you or someone you know is in immediate danger, contact local emergency services.',
            ],
          ),
          const SizedBox(height: 12),
          _buildBullets(
            context,
            const <String>[
              'NCMEC CyberTipline: 1-800-843-5678 or cybertipline.org',
              'FBI IC3: ic3.gov',
              'INHOPE: inhope.org',
            ],
          ),
          const SizedBox(height: 24),
          _buildSection(
            context,
            title: '14. Commitment Statement',
            paragraphs: const <String>[
              'Protecting children from abuse and exploitation is a core safety commitment at Drawback. We will continue strengthening safeguards, cooperating with authorities, and enforcing violations decisively.',
            ],
          ),
          const SizedBox(height: 28),
          Text(
            'End of CSAE Standards',
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
                color: const Color(0xFF7C2D12),
              ),
        ),
        if (paragraphs.isNotEmpty) const SizedBox(height: 12),
        ...paragraphs.map(
          (String paragraph) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: _buildParagraph(context, paragraph),
          ),
        ),
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
            color: const Color(0xFF9F1239),
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

  Widget _buildSubsectionWithParagraphs(
    BuildContext context, {
    required String title,
    required List<String> paragraphs,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          _buildSubsectionTitle(context, title: title),
          const SizedBox(height: 8),
          ...paragraphs.map(
            (String paragraph) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _buildParagraph(context, paragraph),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubsectionWithNumberedItems(
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
          _buildNumberedItems(context, items),
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
                              color: const Color(0xFF9F1239),
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

  Widget _buildNumberedItems(BuildContext context, List<String> items) {
    return Padding(
      padding: const EdgeInsets.only(left: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: List<Widget>.generate(
          items.length,
          (int index) => Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Text(
                    '${index + 1}. ',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: const Color(0xFF9F1239),
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                ),
                Expanded(
                  child: Text(
                    items[index],
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: const Color(0xFF9F1239),
                          height: 1.35,
                        ),
                  ),
                ),
              ],
            ),
          ),
        ),
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
            color: const Color(0xFF9F1239),
            height: 1.4,
            fontWeight: emphasized ? FontWeight.w700 : FontWeight.w400,
          ),
    );
  }
}
