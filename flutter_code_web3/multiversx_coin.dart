// ignore_for_file: non_constant_identifier_names

import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:multiversx_sdk/multiversx.dart' as multiversx;
import 'package:web3dart/crypto.dart';

import '../interface/coin.dart';
import '../main.dart';
import '../utils/app_config.dart';
import '../utils/rpc_urls.dart';

const multiversxDecimals = 18;

final dio = Dio();

class MultiversxCoin extends Coin {
  String blockExplorer;
  String symbol;
  String default_;
  String image;
  String name;
  String rpc;
  @override
  Future<String> address_() async {
    final details = await fromMnemonic(pref.get(currentMmenomicKey));
    return details['address'];
  }

  multiversx.ProxyProvider getProxy() {
    return multiversx.ProxyProvider(
      addressRepository: multiversx.AddressRepository(dio, baseUrl: rpc),
      networkRepository: multiversx.NetworkRepository(dio, baseUrl: rpc),
      transactionRepository: multiversx.TransactionRepository(
        dio,
        baseUrl: rpc,
      ),
    );
  }

  @override
  String blockExplorer_() {
    return blockExplorer;
  }

  @override
  String default__() {
    return default_;
  }

  @override
  String image_() {
    return image;
  }

  @override
  String name_() {
    return name;
  }

  @override
  String symbol_() {
    return symbol;
  }

  MultiversxCoin({
    this.blockExplorer,
    this.symbol,
    this.default_,
    this.image,
    this.name,
    this.rpc,
  });

  factory MultiversxCoin.fromJson(Map<String, dynamic> json) {
    return MultiversxCoin(
      blockExplorer: json['blockExplorer'],
      default_: json['default'],
      symbol: json['symbol'],
      image: json['image'],
      name: json['name'],
      rpc: json['rpc'],
    );
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

    return data;
  }

  @override
  Future<Map> fromMnemonic(String mnemonic) async {
    const keyName = 'multixDetail';
    List mmenomicMapping = [];
    if (pref.get(keyName) != null) {
      mmenomicMapping = jsonDecode(pref.get(keyName)) as List;
      for (int i = 0; i < mmenomicMapping.length; i++) {
        if (mmenomicMapping[i]['mmenomic'] == mnemonic) {
          return mmenomicMapping[i]['key'];
        }
      }
    }

    final keys = await compute(
        calculateMultiversXKey,
        Map.from(toJson())
          ..addAll({
            mnemonicKey: mnemonic,
            seedRootKey: seedPhraseRoot,
          }));
    mmenomicMapping.add({'key': keys, 'mmenomic': mnemonic});
    await pref.put(keyName, jsonEncode(mmenomicMapping));
    return keys;
  }

  @override
  Future<double> getBalance(bool skipNetworkRequest) async {
    final address = await address_();
    final key = 'multiversxAddressBalance$address$rpc';

    final storedBalance = pref.get(key);

    double savedBalance = 0;

    if (storedBalance != null) {
      savedBalance = storedBalance;
    }

    if (skipNetworkRequest) return savedBalance;

    try {
      multiversx.Address addressMul = multiversx.Address.fromBech32(address);

      multiversx.Account userAcct = multiversx.Account.withAddress(addressMul);

      userAcct = await userAcct.synchronize(getProxy());

      final base = BigInt.from(10);

      double fraction = userAcct.balance.value / base.pow(decimals());

      await pref.put(key, fraction);

      return fraction;
    } catch (_) {
      return savedBalance;
    }
  }

  Future<String> trnsTok(Map config) async {
    var keys = await compute(calculateMultiversXKey, {
      mnemonicKey: config[mnemonicKey],
      'getMultixKeys': true,
      seedRootKey: seedPhraseRoot,
    });

    multiversx.Wallet wallet = keys;

    await wallet.synchronize(getProxy());

    final txHash = await wallet.sendEgld(
      provider: getProxy(),
      to: multiversx.Address.fromBech32(config['to']),
      amount: multiversx.Balance.fromEgld(num.parse(config['amount'])),
    );

    return txHash.hash;
  }

  static multiversx.Transaction signTransaction(Map config) {
    multiversx.ISigner signer = config['signer'];
    multiversx.ISignable transaction = config['transaction'];
    return signer.sign(transaction);
  }

  static List<int> signMessage(Map config) {
    multiversx.UserSecretKey signer = config['signer'];
    Uint8List message = config['message'];
    return signer.sign(message);
  }

  @override
  Future<String> transferToken(String amount, String to) async {
    var sendTransaction = await compute(trnsTok, {
      'to': to,
      'amount': amount,
      mnemonicKey: pref.get(currentMmenomicKey),
    });

    return sendTransaction;
  }

  static Uint8List serializeForSigning(String message) {
    Uint8List message_ = ascii.encode(message);
    Uint8List messgSize = ascii.encode(message_.length.toString());

    Uint8List prefix = hexToBytes(
      "17456c726f6e64205369676e6564204d6573736167653a0a",
    );

    return keccak256(Uint8List.fromList(prefix + messgSize + message_));
  }

  @override
  validateAddress(String address) {
    multiversx.Address.fromBech32(address);
  }

  @override
  int decimals() {
    return multiversxDecimals;
  }

  @override
  String savedTransKey() {
    return '$default_$rpc Details';
  }

  @override
  Future<double> getTransactionFee(String amount, String to) async {
    return 0.00005;
  }

  @override
  Future<String> addressExplorer() async {
    final address = await address_();
    return blockExplorer
        .replaceFirst('/transactions/', '/accounts/')
        .replaceFirst(blockExplorerPlaceholder, address);
  }
}

List<Map> getMultiversxBlockChains() {
  List<Map> blockChains = [];
  if (enableTestNet) {
    blockChains.add({
      'name': 'MultiversX(Testnet)',
      'symbol': 'EGLD',
      'default': 'EGLD',
      'blockExplorer':
          'https://testnet-explorer.multiversx.com/transactions/$blockExplorerPlaceholder',
      'image': 'assets/multiversx.webp',
      'rpc': 'https://testnet-gateway.multiversx.com/',
    });
  } else {
    blockChains.addAll([
      {
        'name': 'MultiversX',
        'symbol': 'EGLD',
        'default': 'EGLD',
        'blockExplorer':
            'https://explorer.multiversx.com/transactions/$blockExplorerPlaceholder',
        'image': 'assets/multiversx.webp',
        'rpc': 'https://gateway.multiversx.com/',
      }
    ]);
  }

  return blockChains;
}

Future calculateMultiversXKey(Map config) async {
  multiversx.Wallet wallet =
      await multiversx.Wallet.fromSeed(config[mnemonicKey]);

  if (config['getMultixKeys'] != null && config['getMultixKeys'] == true) {
    return wallet;
  }

  return {
    'address': wallet.account.address.bech32,
  };
}
