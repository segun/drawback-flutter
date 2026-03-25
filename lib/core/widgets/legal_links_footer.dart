import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class LegalLinksFooter extends StatelessWidget {
  const LegalLinksFooter({
    super.key,
    this.fontSize = 11,
    this.linkColor = const Color(0xFF9F1239),
  });

  final double fontSize;
  final Color linkColor;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      alignment: WrapAlignment.center,
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 6,
      children: <Widget>[
        TextButton(
          onPressed: () => context.pushNamed('privacy'),
          style: TextButton.styleFrom(
            foregroundColor: linkColor,
            minimumSize: const Size(0, 0),
            padding: EdgeInsets.zero,
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
          child: Text(
            'Privacy',
            style: TextStyle(
              fontSize: fontSize,
              decoration: TextDecoration.underline,
            ),
          ),
        ),
        Text(
          '|',
          style: TextStyle(
            fontSize: fontSize,
            color: linkColor,
          ),
        ),
        TextButton(
          onPressed: () => context.pushNamed('eula'),
          style: TextButton.styleFrom(
            foregroundColor: linkColor,
            minimumSize: const Size(0, 0),
            padding: EdgeInsets.zero,
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
          child: Text(
            'Terms',
            style: TextStyle(
              fontSize: fontSize,
              decoration: TextDecoration.underline,
            ),
          ),
        ),
        Text(
          '|',
          style: TextStyle(
            fontSize: fontSize,
            color: linkColor,
          ),
        ),
        TextButton(
          onPressed: () => context.pushNamed('csae'),
          style: TextButton.styleFrom(
            foregroundColor: linkColor,
            minimumSize: const Size(0, 0),
            padding: EdgeInsets.zero,
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
          child: Text(
            'CSAE',
            style: TextStyle(
              fontSize: fontSize,
              decoration: TextDecoration.underline,
            ),
          ),
        ),
      ],
    );
  }
}
