import 'package:flutter/material.dart';
import 'package:m_reground/config/app_config.dart';
import 'package:m_reground/core/services/auth_service.dart';

class AuthGate extends StatefulWidget {
  const AuthGate({super.key, required this.onAuthenticated});

  final ValueChanged<AuthUser> onAuthenticated;

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _emailLinkController = TextEditingController();
  bool _loading = false;
  String? _error;
  String? _info;

  Future<void> _requestEmailOtpOrBypass() async {
    setState(() {
      _loading = true;
      _error = null;
      _info = null;
    });
    try {
      final AuthUser? user = await AuthService.instance.requestEmailOtpOrBypass(_emailController.text);
      if (user != null) {
        widget.onAuthenticated(user);
      } else {
        setState(() {
          _info = 'OTP link sent to your email. Paste the received link below to verify.';
        });
      }
    } catch (e) {
      setState(() {
        _error = e.toString();
      });
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  Future<void> _verifyEmailOtpLink() async {
    setState(() {
      _loading = true;
      _error = null;
      _info = null;
    });
    try {
      final AuthUser user = await AuthService.instance.completeEmailOtpSignIn(
        emailLink: _emailLinkController.text.trim(),
      );
      widget.onAuthenticated(user);
    } catch (e) {
      setState(() {
        _error = e.toString();
      });
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  Future<void> _continueAsDemoUser() async {
    _emailController.text = AppConfig.demoCustomerEmail;
    setState(() {
      _loading = true;
      _error = null;
      _info = null;
    });
    try {
      final AuthUser? user = await AuthService.instance.requestEmailOtpOrBypass(
        AppConfig.demoCustomerEmail,
      );
      if (user != null) {
        widget.onAuthenticated(user);
      } else {
        setState(() {
          _info = 'Demo sign-in link sent. Paste the received link below to continue.';
        });
      }
    } catch (e) {
      setState(() {
        _error = e.toString();
      });
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  Future<void> _signInWithGoogle() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final AuthUser user = await AuthService.instance.signInWithGoogle();
      widget.onAuthenticated(user);
    } catch (e) {
      setState(() {
        _error = e.toString();
      });
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 460),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  const Text(
                    'M-ReGround',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 36, fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Break social media loops with intentional friction.',
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  TextField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      labelText: 'Email',
                      hintText: 'you@example.com',
                    ),
                  ),
                  const SizedBox(height: 12),
                  FilledButton(
                    onPressed: _loading ? null : _requestEmailOtpOrBypass,
                    child: const Text('Send Email OTP Link / Bypass'),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: _emailLinkController,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      labelText: 'OTP Email Link',
                      hintText: 'Paste email sign-in link here',
                    ),
                  ),
                  const SizedBox(height: 8),
                  FilledButton.tonal(
                    onPressed: _loading ? null : _verifyEmailOtpLink,
                    child: const Text('Verify Email OTP Link'),
                  ),
                  const SizedBox(height: 8),
                  FilledButton(
                    onPressed: _loading ? null : _continueAsDemoUser,
                    child: const Text('Continue as Demo User'),
                  ),
                  const SizedBox(height: 8),
                  OutlinedButton(
                    onPressed: _loading ? null : _signInWithGoogle,
                    child: const Text('Continue with Google'),
                  ),
                  if (_info != null) ...<Widget>[
                    const SizedBox(height: 12),
                    Text(_info!, style: const TextStyle(color: Colors.green)),
                  ],
                  if (_error != null) ...<Widget>[
                    const SizedBox(height: 12),
                    Text(_error!, style: const TextStyle(color: Colors.red)),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
