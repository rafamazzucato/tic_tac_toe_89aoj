import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:tic_toc_toe/models/game.dart';
import 'package:tic_toc_toe/models/message.dart';
import 'package:tic_toc_toe/utils/constants.dart';

class GameWidget extends StatefulWidget {
  const GameWidget({super.key});

  @override
  State<GameWidget> createState() => _GameWidgetState();
}

class _GameWidgetState extends State<GameWidget> {
  static const platform = MethodChannel('game/exchange');

  Game? game;
  bool? minhaVez;

  // 0 = branco, 1 eu escolhi essa celula e 2 oponente escolheu a celula
  List<List<int>> cells = [
    [0, 0, 0],
    [0, 0, 0],
    [0, 0, 0],
  ];

  @override
  void initState() {
    super.initState();
    _configureMethodChannelCallback();
  }

  _configureMethodChannelCallback() {
    platform.setMethodCallHandler((call) async {
      print('Platform received: $call');

      final action = call.method;
      final arguments = call.arguments.toString().replaceAll("\"", "");
      final splitted = arguments.split("|");

      if (action == "sendAction") {
        final message = Message(
            splitted[0], int.parse(splitted[1]), int.parse(splitted[2]));

        if (message.user == (game!.creator ? "p2" : "p1")) {
          setState(() {
            minhaVez = true;
            cells[message.x][message.y] = 2;
          });

          _checkWinner();
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    ScreenUtil.init(context, designSize: const Size(700, 1400));

    return Scaffold(
      body: SingleChildScrollView(
        child: Stack(
          children: [
            Column(
              children: [
                Row(
                  children: [
                    Container(
                      width: ScreenUtil().setWidth(550),
                      height: ScreenUtil().setHeight(550),
                      color: colorBackBlue1,
                    ),
                    Container(
                      width: ScreenUtil().setWidth(150),
                      height: ScreenUtil().setHeight(550),
                      color: colorBackBlue2,
                    ),
                  ],
                ),
                Container(
                  width: ScreenUtil().setWidth(700),
                  height: ScreenUtil().setHeight(850),
                  color: colorBackBlue3,
                ),
              ],
            ),
            SizedBox(
              height: ScreenUtil().setHeight(1400),
              width: ScreenUtil().setWidth(700),
              child: Center(
                  child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                    (game == null
                        ? Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                                _buildButton("Criar", true),
                                const SizedBox(width: 10),
                                _buildButton("Entrar", false),
                              ])
                        : InkWell(
                            onLongPress: (() {}),
                            child: Text(
                              minhaVez == true
                                  ? "Sua vez!!"
                                  : "Aguarde sua vez!!",
                              style: textStyle36,
                            ))),
                    GridView.count(
                      shrinkWrap: true,
                      padding: const EdgeInsets.all(20),
                      mainAxisSpacing: 10,
                      crossAxisSpacing: 10,
                      crossAxisCount: 3,
                      children: [
                        _getCell(0, 0),
                        _getCell(0, 1),
                        _getCell(0, 2),
                        _getCell(1, 0),
                        _getCell(1, 1),
                        _getCell(1, 2),
                        _getCell(2, 0),
                        _getCell(2, 1),
                        _getCell(2, 2),
                      ],
                    )
                  ])),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildButton(String label, bool isCreator) => SizedBox(
        width: ScreenUtil().setWidth(300),
        child: OutlinedButton(
            child: Padding(
                padding: paddingDefault,
                child: Text(label, style: textStyle36)),
            onPressed: () {
              _createGame(isCreator);
            }),
      );

  Widget _getCell(int x, int y) {
    return InkWell(
        child: Container(
          padding: paddingDefault,
          color: Colors.lightBlueAccent,
          child: Center(
              child: Text(
            cells[x][y] == 0
                ? " "
                : cells[x][y] == 1
                    ? "X"
                    : "0",
            style: textStyle72,
          )),
        ),
        onTap: () async {
          if (minhaVez == true && cells[x][y] == 0) {
            final result = await _sendAction(
                'sendAction', {'tap': '${game!.creator ? 'p1' : 'p2'}|$x|$y'});
            if (result) {
              setState(() {
                minhaVez = false;
                cells[x][y] = 1;
              });
              _checkWinner();
            }
          }
        });
  }

  Future _createGame(bool isCreator) {
    final editingController = TextEditingController();
    return showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) {
          return AlertDialog(
            title: const Text("Qual o nome do jogo?"),
            content: TextField(
              controller: editingController,
            ),
            actions: [
              ElevatedButton(
                  onPressed: () async {
                    Navigator.pop(context);
                    final result = await _sendAction(
                        'subscribe', {'channel': editingController.text});
                    if (result) {
                      setState(() {
                        game = Game(editingController.text, isCreator);
                        minhaVez = isCreator;
                      });
                    }
                  },
                  child: const Text("Jogar")),
              ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  child: const Text("Cancelar"))
            ],
          );
        });
  }

  Future<bool> _sendAction(
      String action, Map<String, dynamic> arguments) async {
    try {
      final result = await platform.invokeMethod(action, arguments);
      if (result) {
        return true;
      }
    } on PlatformException catch (e) {
      print('Ocorreu erro ao enviar ação: $e');
    }

    return false;
  }

  _checkWinner() {
    bool youWin = false;
    bool enemyWin = false;

    if (cells[0][0] != 0 &&
        cells[0][0] == cells[0][1] &&
        cells[0][1] == cells[0][2]) {
      if (cells[0][0] == 1) {
        youWin = true;
      }
      enemyWin = true;
    } else if (cells[1][0] != 0 &&
        cells[1][0] == cells[1][1] &&
        cells[1][1] == cells[1][2]) {
      if (cells[1][0] == 1) {
        youWin = true;
      }
      enemyWin = true;
    } else if (cells[2][0] != 0 &&
        cells[2][0] == cells[2][1] &&
        cells[2][1] == cells[2][2]) {
      if (cells[2][0] == 1) {
        youWin = true;
      }
      enemyWin = true;
    } else if (cells[0][0] != 0 &&
        cells[0][0] == cells[1][0] &&
        cells[1][0] == cells[2][0]) {
      if (cells[0][0] == 1) {
        youWin = true;
      }
      enemyWin = true;
    } else if (cells[0][1] != 0 &&
        cells[0][1] == cells[1][1] &&
        cells[1][1] == cells[2][1]) {
      if (cells[0][1] == 1) {
        youWin = true;
      }
      enemyWin = true;
    } else if (cells[0][2] != 0 &&
        cells[0][2] == cells[1][2] &&
        cells[1][2] == cells[2][2]) {
      if (cells[0][2] == 1) {
        youWin = true;
      }
      enemyWin = true;
    } else if (cells[0][0] != 0 &&
        cells[0][0] == cells[1][1] &&
        cells[1][1] == cells[2][2]) {
      if (cells[0][0] == 1) {
        youWin = true;
      }
      enemyWin = true;
    } else if (cells[0][2] != 0 &&
        cells[0][2] == cells[1][1] &&
        cells[1][1] == cells[2][0]) {
      if (cells[0][2] == 1) {
        youWin = true;
      }
      enemyWin = true;
    }

    if (youWin) {
      _showFinishGame(true);
    } else if (enemyWin) {
      _showFinishGame(false);
    } else {
      bool allPlaysDone = true;
      for (var line in cells) {
        for (var column in line) {
          if (allPlaysDone == false) break;
          if (column == 0) {
            allPlaysDone = false;
            break;
          }
        }
      }
      if (allPlaysDone == true) _showFinishGame(null);
    }
  }

  Future _showFinishGame(bool? youWin) {
    return showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) {
          return AlertDialog(
            title: const Text("FIM DE JOGO!!!"),
            content: Text(youWin == true
                ? "Você ganhou"
                : youWin == false
                    ? "Você perdeu"
                    : "Não houve ganhadores"),
            actions: [
              ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    setState(() {
                      game = null;
                      bool? minhaVez = false;

                      cells = [
                        [0, 0, 0],
                        [0, 0, 0],
                        [0, 0, 0],
                      ];
                    });
                  },
                  child: const Text("Fechar"))
            ],
          );
        });
  }
}
