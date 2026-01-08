import net.http
import json
import crypto.rand
import os

fn send_evm_transaction() ? {
    rpc_url := os.getenv('SEPOLIA_RPC_URL')?
    private_key := os.getenv('PRIVATE_KEY')?
    sender_address := os.getenv('SENDER_ADDRESS')?
    
    recipients := [
        "0xAb5801a7D398351b8bE11C439e05C5B3259aeC9B",
        "0x1Db3439a222C519ab44bb1144fC28167b4Fa6EE6",
        "0x3fC91A3afd70395Cd496C647d5a6CC9D4B2b7FAD",
    ]
    
    random_index := rand.int_in_range(0, recipients.len)?
    recipient := recipients[random_index]
    
    min_amount := 0.0001
    max_amount := 0.001
    amount := min_amount + rand.f64() * (max_amount - min_amount)
    amount_wei := u64(amount * 1000000000000000000)
    
    balance_response := http.post_json(rpc_url, json.encode({
        "jsonrpc": "2.0",
        "method": "eth_getBalance",
        "params": [sender_address, "latest"],
        "id": 1
    }))?
    
    balance := json.decode(map[string]json.Any, balance_response.text)?["result"] or { "0x0" }.str()
    balance_int := u64(balance.u64())
    
    if balance_int < amount_wei {
        return error("Insufficient balance")
    }
    
    nonce_response := http.post_json(rpc_url, json.encode({
        "jsonrpc": "2.0",
        "method": "eth_getTransactionCount",
        "params": [sender_address, "latest"],
        "id": 2
    }))?
    
    nonce := json.decode(map[string]json.Any, nonce_response.text)?["result"].str()
    
    gas_price_response := http.post_json(rpc_url, json.encode({
        "jsonrpc": "2.0",
        "method": "eth_gasPrice",
        "params": [],
        "id": 3
    }))?
    
    gas_price := json.decode(map[string]json.Any, gas_price_response.text)?["result"].str()
    
    tx_data := json.encode({
        "from": sender_address,
        "to": recipient,
        "value": "0x${amount_wei:x}",
        "gas": "0x5208",
        "gasPrice": gas_price,
        "nonce": nonce,
        "chainId": "0xaa36a7"
    })
    
    println("Transaction: $tx_data")
    
    // Note: V doesn't have built-in ECDSA signing yet
    // Need external library for signing
}

fn main() {
    send_evm_transaction() or { println("Error: $err") }
}
