import hashlib
import json
from time import time
from datetime import datetime

class BlockchainManager:
    def __init__(self, chain_file='chain.json'):
        self.chain_file = chain_file
        self.chain = self.load_chain()
        if not self.chain:
            # Create the genesis block if no chain exists
            self.add_new_block(proof=100, previous_hash='1', data={"message": "Genesis Block"})

    def load_chain(self):
        try:
            with open(self.chain_file, 'r') as f:
                return json.load(f)
        except (IOError, json.JSONDecodeError):
            return []

    def save_chain(self):
        with open(self.chain_file, 'w') as f:
            json.dump(self.chain, f, indent=4)

    def add_new_block(self, data, proof=None, previous_hash=None):
        block = {
            'index': len(self.chain) + 1,
            'timestamp': str(datetime.utcnow()),
            'data': data,
            'proof': proof or self.proof_of_work(self.last_block['proof']),
            'previous_hash': previous_hash or self.hash(self.last_block),
        }
        self.chain.append(block)
        self.save_chain()
        return block

    @property
    def last_block(self):
        return self.chain[-1]

    @staticmethod
    def hash(block):
        block_string = json.dumps(block, sort_keys=True).encode()
        return hashlib.sha256(block_string).hexdigest()

    def proof_of_work(self, last_proof):
        proof = 0
        while self.valid_proof(last_proof, proof) is False:
            proof += 1
        return proof

    @staticmethod
    def valid_proof(last_proof, proof):
        guess = f'{last_proof}{proof}'.encode()
        guess_hash = hashlib.sha256(guess).hexdigest()
        return guess_hash[:4] == "0000"

blockchain_manager = BlockchainManager()