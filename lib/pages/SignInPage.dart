import 'package:awesome_dialog/awesome_dialog.dart';
import 'package:flutter/material.dart';
import 'package:ubus/components/DecorationInput.dart';
import 'package:ubus/pages/DriverMapPage.dart';
import 'package:ubus/pages/HomePage.dart';
import 'package:ubus/services/AuthService.dart';

class SignInPage extends StatefulWidget {
  const SignInPage({super.key});

  @override
  State<SignInPage> createState() => _SignInPageState();
}

AuthService authService = AuthService();

TextEditingController _emailControllerSgIn = TextEditingController();

TextEditingController _passwordControllerSgIn = TextEditingController();

FocusNode emailFocusNode = FocusNode();
FocusNode passwordFocusNode = FocusNode();

class _SignInPageState extends State<SignInPage> {
  final _formKeySgIn = GlobalKey<FormState>();
  bool isTextHidden = true;
  bool isLoading = false;

  toggleShowPassword() {
    if (isTextHidden) {
      setState(() {
        isTextHidden = false;
      });
    } else {
      setState(() {
        isTextHidden = true;
      });
    }
  }

  @override
  void initState() {
    _emailControllerSgIn.text = '';
    _passwordControllerSgIn.text = '';
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: MediaQuery.of(context).viewInsets.bottom == 0.0
          ? AppBar(
              iconTheme: const IconThemeData(color: Colors.white),
              backgroundColor: const Color.fromARGB(0, 0, 87, 218),
              leading: IconButton(
                icon: const Icon(
                  Icons.home,
                  size: 30,
                ),
                onPressed: () {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const HomePage(),
                    ),
                  );
                },
              ),
            )
          : null,
      backgroundColor: const Color(0xFF0469ff),
      body: Form(
        key: _formKeySgIn,
        child: !isLoading
            ? SizedBox(
                height: MediaQuery.sizeOf(context).height,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Image.asset(
                      "assets/splash.png",
                      fit: BoxFit.contain,
                      height: 220,
                    ),
                    const SizedBox(
                      height: 15,
                    ),
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: TextFormField(
                        validator: (value) {
                          if (value!.isEmpty) {
                            return "Por favor, preencha este campo!";
                          }
                          if (value.length < 5) {
                            return "O e-mail é muito curto";
                          }
                          if (!value.contains("@")) {
                            return null;
                          }
                          return null;
                        },
                        controller: _emailControllerSgIn,
                        focusNode: emailFocusNode,
                        onFieldSubmitted: (value) => FocusScope.of(context)
                            .requestFocus(passwordFocusNode),
                        decoration: getInputDecoration(
                          "Email",
                          errorStyle: const TextStyle(color: Colors.yellow),
                        ),
                      ),
                    ),
                    Flexible(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: TextFormField(
                          validator: (value) {
                            if (value!.isEmpty) {
                              return "Por favor, preencha este campo!";
                            }
                            if (value.length < 3) {
                              return "A senha é muito curta";
                            }
                            return null;
                          },
                          controller: _passwordControllerSgIn,
                          focusNode: passwordFocusNode,
                          decoration: getInputDecoration(
                            "Senha",
                            sufx_iconBtn: IconButton(
                              onPressed: toggleShowPassword,
                              icon: !isTextHidden
                                  ? const Icon(
                                      Icons.visibility,
                                      size: 30,
                                    )
                                  : const Icon(
                                      Icons.visibility_off,
                                      size: 30,
                                    ),
                            ),
                            errorStyle: const TextStyle(color: Colors.yellow),
                          ),
                          obscureText: isTextHidden,
                        ),
                      ),
                    ),
                    MediaQuery.of(context).viewInsets.bottom == 0.0
                        ? Padding(
                            padding: const EdgeInsets.all(18.0),
                            child: ElevatedButton(
                              onPressed: signIn,
                              child: const Text("Entrar"),
                            ),
                          )
                        : Container()
                  ],
                ),
              )
            : const Center(
                child: CircularProgressIndicator(
                  color: Colors.white,
                ),
              ),
      ),
    );
  }

  signIn() async {
    String email = _emailControllerSgIn.text;
    String password = _passwordControllerSgIn.text;

    if (_formKeySgIn.currentState!.validate()) {
      setState(() {
        isLoading = true;
      });
      await authService
          .logUser(email: email, password: password)
          .then((String? error) {
        if (error != null) {
          AwesomeDialog(
                  context: context,
                  dialogType: DialogType.error,
                  title: "Ocorreu um erro ao logar!",
                  dismissOnBackKeyPress: false,
                  dismissOnTouchOutside: false,
                  btnOkOnPress: () {
                    setState(() {
                      isLoading = false;
                    });
                  },
                  desc: error)
              .show();
        } else {
          if (mounted) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => const DriverMapPage(),
              ),
            );
          }
        }
      });
    } else {
      print("Form invalid");
    }
  }
}
