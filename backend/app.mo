import HashMap "mo:base/HashMap";
import Principal "mo:base/Principal";
import Text "mo:base/Text";
import Nat "mo:base/Nat";
import Iter "mo:base/Iter";
import Result "mo:base/Result";

actor TokenManager {
    // Tipe data untuk token
    type Token = {
        name: Text;
        symbol: Text;
        totalSupply: Nat;
        owner: Principal;
    };

    // Tipe data untuk akun
    type Account = {
        owner: Principal;
        balance: Nat;
    };

    // Variabel state untuk menyimpan token dan akun
    private var tokens = HashMap.HashMap<Text, Token>(10, Text.equal, Text.hash);
    private var tokenBalances = HashMap.HashMap<Text, HashMap.HashMap<Principal, Nat>>(10, Text.equal, Text.hash);

    // Membuat token baru
    public shared(msg) func createToken(
        name: Text, 
        symbol: Text, 
        initialSupply: Nat
    ) : async Result.Result<Text, Text> {
        // Validasi input
        if (Text.size(name) == 0 or Text.size(symbol) == 0 or initialSupply == 0) {
            return #err("Invalid token parameters");
        };

        // Cek apakah token sudah ada
        if (tokens.get(symbol) != null) {
            return #err("Token already exists");
        };

        // Buat token baru
        let newToken : Token = {
            name = name;
            symbol = symbol;
            totalSupply = initialSupply;
            owner = msg.caller
        };

        // Buat peta saldo untuk token
        let balanceMap = HashMap.HashMap<Principal, Nat>(10, Principal.equal, Principal.hash);
        balanceMap.put(msg.caller, initialSupply);

        // Simpan token dan saldo
        tokens.put(symbol, newToken);
        tokenBalances.put(symbol, balanceMap);

        #ok(symbol)
    };

    // Transfer token
    public shared(msg) func transferToken(
        symbol: Text, 
        to: Principal, 
        amount: Nat
    ) : async Result.Result<Nat, Text> {
        // Validasi token
        switch (tokenBalances.get(symbol)) {
            case null { return #err("Token not found"); };
            case (?balanceMap) {
                // Cek saldo pengirim
                switch (balanceMap.get(msg.caller)) {
                    case null { return #err("Insufficient balance"); };
                    case (?senderBalance) {
                        if (senderBalance < amount) {
                            return #err("Insufficient balance");
                        };

                        // Kurangi saldo pengirim
                        balanceMap.put(msg.caller, senderBalance - amount);

                        // Tambah saldo penerima
                        switch (balanceMap.get(to)) {
                            case null { 
                                balanceMap.put(to, amount); 
                            };
                            case (?receiverBalance) {
                                balanceMap.put(to, receiverBalance + amount);
                            };
                        };

                        return #ok(amount);
                    };
                };
            };
        };
    };

    // Dapatkan saldo token
    public query func getTokenBalance(
        symbol: Text, 
        account: Principal
    ) : async ?Nat {
        switch (tokenBalances.get(symbol)) {
            case null { null };
            case (?balanceMap) {
                balanceMap.get(account)
            };
        }
    };

    // Dapatkan detail token
    public query func getTokenDetails(symbol: Text) : async ?Token {
        tokens.get(symbol)
    };

    // Dapatkan semua token yang dibuat
    public query func getAllTokens() : async [(Text, Token)] {
        Iter.toArray(tokens.entries())
    };
}
