//

import 'dart:convert';
import 'dart:math';

import 'package:cryptowallet/coins/multiversx_coin.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart';

import '../main.dart';
import '../model/esdt_balance_model.dart';
import '../utils/app_config.dart';
import 'package:multiversx_sdk/multiversx.dart' as multiversx;

import '../utils/rpc_urls.dart';

class ESDTCoin extends MultiversxCoin {
  String identifier;
  int decimals_;
  ESDTCoin({
    String blockExplorer,
    int chainId,
    String symbol,
    String default_,
    String image,
    int coinType,
    String rpc,
    String name,
    this.identifier,
    this.decimals_,
  }) : super(
          blockExplorer: blockExplorer,
          symbol: symbol,
          default_: default_,
          image: image,
          rpc: rpc,
          name: name,
        );

  @override
  int decimals() {
    return decimals_;
  }

  factory ESDTCoin.fromJson(Map<String, dynamic> json) {
    return ESDTCoin(
      chainId: json['chainId'],
      rpc: json['rpc'],
      coinType: json['coinType'],
      blockExplorer: json['blockExplorer'],
      default_: json['default'],
      symbol: json['symbol'],
      identifier: json['identifier'],
      image: json['image'],
      name: json['name'],
      decimals_: json['decimals'].runtimeType == String
          ? int.parse(json['decimals'])
          : json['decimals'],
    );
  }

  Future<String> trnsCoin(Map config) async {
    var keys = await compute(calculateMultiversXKey, {
      mnemonicKey: config[mnemonicKey],
      'getMultixKeys': true,
      seedRootKey: seedPhraseRoot,
    });

    multiversx.Wallet wallet = keys;

    await wallet.synchronize(getProxy());

    BigInt amount = BigInt.from(
      double.parse(config['amount']) * pow(10, decimals()),
    );
    final txHash = await wallet.sendEsdt(
      identifier: identifier,
      provider: getProxy(),
      to: multiversx.Address.fromBech32(config['to']),
      amount: multiversx.Balance.fromString('$amount'),
    );

    return txHash.hash;
  }

  @override
  Future<double> getBalance(bool skipNetworkRequest) async {
    final address = await address_();
    final key = 'ESDTddressBalance$identifier$rpc$address';

    final storedBalance = pref.get(key);

    double savedBalance = 0;

    if (storedBalance != null) {
      savedBalance = storedBalance;
    }

    if (skipNetworkRequest) return savedBalance;

    try {
      final url = '${rpc}address/$address/esdt/$identifier';

      final request = await get(Uri.parse(url));
      final responseBody = request.body;

      if (request.statusCode ~/ 100 == 4 || request.statusCode ~/ 100 == 5) {
        throw Exception(responseBody);
      }

      EsdtBalanceModel esdtBalanceModel =
          EsdtBalanceModel.fromJson(json.decode(responseBody));
      final balance = esdtBalanceModel.data.tokenData.balance;

      final base = BigInt.from(10);

      double fraction = BigInt.parse(balance) / base.pow(decimals_);

      await pref.put(key, fraction);

      return fraction;
    } catch (_) {
      return savedBalance;
    }
  }

  @override
  Future<String> transferToken(String amount, String to) async {
    var sendTransaction = await compute(trnsCoin, {
      'to': to,
      'amount': amount,
      mnemonicKey: pref.get(currentMmenomicKey),
    });

    return sendTransaction;
  }

  @override
  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};

    data['rpc'] = rpc;
    data['default'] = default_;
    data['symbol'] = symbol;
    data['name'] = name;
    data['blockExplorer'] = blockExplorer;
    data['image'] = image;
    data['identifier'] = identifier;
    data['decimals'] = decimals_;

    return data;
  }

  @override
  String savedTransKey() {
    return '$identifier$rpc Details';
  }

  @override
  Future<double> getTransactionFee(String amount, String to) async {
    return 0;
  }
}

List<Map> getESDTCoins() {
  List<Map> blockChains = [];
  if (enableTestNet) {
    blockChains.addAll([
      {
        'name': 'VEGLD(Testnet)',
        'symbol': 'VEGLD',
        'default': 'EGLD',
        'blockExplorer':
            'https://testnet-explorer.multiversx.com/transactions/$blockExplorerPlaceholder',
        'image': 'assets/ashswap.png',
        'rpc': 'https://testnet-gateway.multiversx.com/',
        'identifier': 'VEGLD-6bc4cb',
        'decimals': 18,
      }
    ]);
  } else {
    blockChains.addAll([
      {
        'name': 'AshSwap',
        'symbol': 'ASH',
        'default': 'EGLD',
        'blockExplorer':
            'https://explorer.multiversx.com/transactions/$blockExplorerPlaceholder',
        'image': 'assets/ashswap.png',
        'rpc': 'https://gateway.multiversx.com/',
        'identifier': 'ASH-a642d1',
        'decimals': 18,
      },
      {
        'name': 'WrappedEGLD',
        'symbol': 'WEGLD',
        'default': 'EGLD',
        'blockExplorer':
            'https://explorer.multiversx.com/transactions/$blockExplorerPlaceholder',
        'image': 'assets/wEGLD.png',
        'rpc': 'https://gateway.multiversx.com/',
        'identifier': 'WEGLD-bd4d79',
        'decimals': 18,
      },
      {
        'name': 'WrappedUSDC',
        'symbol': 'USDC',
        'default': 'USDC-c76f1f',
        'blockExplorer':
            'https://explorer.multiversx.com/transactions/$blockExplorerPlaceholder',
        'image': 'assets/wusd.png',
        'rpc': 'https://gateway.multiversx.com/',
        'identifier': 'USDC-c76f1f',
        'decimals': 6,
      },
      {
        'name': 'ZoidPay',
        'symbol': 'ZPAY',
        'default': 'EGLD',
        'blockExplorer':
            'https://explorer.multiversx.com/transactions/$blockExplorerPlaceholder',
        'image': 'assets/zpay.png',
        'rpc': 'https://gateway.multiversx.com/',
        'identifier': 'ZPAY-247875',
        'decimals': 18,
      },
    ]);
  }

  return blockChains;
}
