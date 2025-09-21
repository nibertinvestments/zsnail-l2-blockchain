// ZSnailScan Frontend JavaScript - Complete Netlify Version
class ZSnailScanApp {
    constructor() {
        this.rpcURL = '/rpc';  // Use Netlify proxy endpoint
        this.chainId = 66875;
        this.refreshInterval = null;
        this.init();
    }

    async init() {
        await this.loadNetworkStats();
        await this.loadLatestBlocks();
        this.setupEventListeners();
        this.startAutoRefresh();
    }

    setupEventListeners() {
        const searchInput = document.getElementById('searchInput');
        if (searchInput) {
            searchInput.addEventListener('keypress', (e) => {
                if (e.key === 'Enter') {
                    this.performSearch();
                }
            });
        }
        window.performSearch = () => this.performSearch();
    }

    async loadNetworkStats() {
        try {
            // Get latest block number
            const blockNumber = await this.rpcCall('eth_blockNumber');
            const latestBlock = parseInt(blockNumber, 16);
            this.updateElement('latestBlock', latestBlock.toLocaleString());
            
            // Get gas price
            const gasPrice = await this.rpcCall('eth_gasPrice');
            const gasPriceGwei = parseInt(gasPrice, 16) / 1e9;
            this.updateElement('gasPrice', `${gasPriceGwei.toFixed(2)} Gwei`);
            
            // Get chain ID
            const chainId = await this.rpcCall('eth_chainId');
            this.updateElement('chainId', parseInt(chainId, 16));
            
            // Get latest block details
            const latestBlockData = await this.rpcCall('eth_getBlockByNumber', ['latest', false]);
            if (latestBlockData) {
                this.updateElement('difficulty', parseInt(latestBlockData.difficulty || '0x0', 16).toLocaleString());
                this.updateElement('minerAddress', this.shortenAddress(latestBlockData.miner) || 'N/A');
            }
            
            // Static values for ZSnail network
            this.updateElement('consensus', 'Proof of Work');
            this.updateElement('totalBlocks', latestBlock.toLocaleString());
            this.updateElement('totalSupply', 'Loading...');
            this.updateElement('connectedWallets', 'N/A');
            
            const statusElement = document.getElementById('networkStatus');
            if (statusElement) {
                statusElement.innerHTML = `<span class="network-indicator online"></span>Online`;
            }
        } catch (error) {
            this.showError('Failed to connect to ZSnail L2 blockchain');
        }
    }

    async rpcCall(method, params = []) {
        try {
            const response = await fetch(this.rpcURL, {
                method: 'POST',
                headers: {
                    'Content-Type': 'application/json',
                },
                body: JSON.stringify({
                    jsonrpc: '2.0',
                    method: method,
                    params: params,
                    id: Date.now()
                })
            });
            
            if (!response.ok) {
                throw new Error(`HTTP ${response.status}`);
            }
            
            const data = await response.json();
            if (data.error) {
                throw new Error(data.error.message);
            }
            
            return data.result;
        } catch (error) {
            console.error(`RPC call failed for ${method}:`, error);
            throw error;
        }
    }

    async loadLatestBlocks() {
        try {
            const latestBlockNumber = await this.rpcCall('eth_blockNumber');
            const latestBlockNum = parseInt(latestBlockNumber, 16);
            
            const tbody = document.getElementById('latestBlocksTable');
            if (!tbody) return;
            
            const promises = [];
            const blocksToShow = Math.min(5, latestBlockNum + 1);
            
            for (let i = 0; i < blocksToShow; i++) {
                const blockNum = latestBlockNum - i;
                if (blockNum >= 0) {
                    promises.push(this.rpcCall('eth_getBlockByNumber', [`0x${blockNum.toString(16)}`, false]));
                }
            }
            
            const blocks = await Promise.all(promises);
            
            tbody.innerHTML = blocks.filter(block => block).map(block => {
                const blockNumber = parseInt(block.number, 16);
                const timestamp = parseInt(block.timestamp, 16);
                const txCount = block.transactions ? block.transactions.length : 0;
                
                return `
                    <tr onclick="window.searchBlock(${blockNumber})" style="cursor: pointer;">
                        <td><span class="badge bg-primary">${blockNumber}</span></td>
                        <td><code>${this.shortenHash(block.hash)}</code></td>
                        <td>${txCount}</td>
                        <td><code>${this.shortenAddress(block.miner)}</code></td>
                        <td>${this.formatTimestamp(timestamp)}</td>
                    </tr>
                `;
            }).join('');
            
        } catch (error) {
            const tbody = document.getElementById('latestBlocksTable');
            if (tbody) {
                tbody.innerHTML = '<tr><td colspan="5" class="text-center text-danger">Failed to load blocks</td></tr>';
            }
        }
    }

    async performSearch() {
        const query = document.getElementById('searchInput').value.trim();
        if (!query) return;
        
        this.showLoading();
        
        try {
            if (query.startsWith('0x') && query.length === 42) {
                await this.searchWallet(query);
            } else if (!isNaN(query)) {
                await this.searchBlock(parseInt(query));
            } else if (query.startsWith('0x') && query.length === 66) {
                await this.searchTransaction(query);
            } else {
                this.showError('Invalid search query. Please enter a wallet address, block number, or transaction hash.');
            }
        } catch (error) {
            this.showError('Search failed: ' + error.message);
        } finally {
            this.hideLoading();
        }
    }

    async searchWallet(address) {
        try {
            // Get balance using JSON-RPC
            const balance = await this.rpcCall('eth_getBalance', [address, 'latest']);
            const nonce = await this.rpcCall('eth_getTransactionCount', [address, 'latest']);
            
            // Convert balance from wei to ZSNAIL (assuming 18 decimals)
            const balanceInZSnail = parseInt(balance, 16) / 1e18;
            
            this.displayResult({
                type: 'Wallet',
                title: `Wallet: ${this.shortenAddress(address)}`,
                data: [
                    { label: 'Address', value: address },
                    { label: 'Balance', value: `${balanceInZSnail.toLocaleString()} ZSNAIL` },
                    { label: 'Nonce', value: parseInt(nonce, 16) },
                    { label: 'Type', value: 'Standard' },
                    { label: 'Network', value: 'ZSnail L2' }
                ]
            });
        } catch (error) {
            throw new Error('Wallet not found or invalid address');
        }
    }

    async searchBlock(blockNumber) {
        try {
            const blockHex = `0x${blockNumber.toString(16)}`;
            const block = await this.rpcCall('eth_getBlockByNumber', [blockHex, true]);
            
            if (!block) {
                throw new Error('Block not found');
            }
            
            const timestamp = parseInt(block.timestamp, 16);
            const gasUsed = parseInt(block.gasUsed || '0x0', 16);
            const gasLimit = parseInt(block.gasLimit || '0x0', 16);
            const difficulty = parseInt(block.difficulty || '0x0', 16);
            
            this.displayResult({
                type: 'Block',
                title: `Block #${blockNumber}`,
                data: [
                    { label: 'Hash', value: block.hash },
                    { label: 'Parent Hash', value: block.parentHash },
                    { label: 'Miner', value: block.miner },
                    { label: 'Timestamp', value: new Date(timestamp * 1000).toLocaleString() },
                    { label: 'Transactions', value: block.transactions?.length || 0 },
                    { label: 'Difficulty', value: difficulty.toLocaleString() },
                    { label: 'Nonce', value: block.nonce },
                    { label: 'Gas Used', value: gasUsed.toLocaleString() },
                    { label: 'Gas Limit', value: gasLimit.toLocaleString() }
                ]
            });
        } catch (error) {
            throw new Error('Block not found');
        }
    }

    async searchTransaction(hash) {
        try {
            const tx = await this.rpcCall('eth_getTransactionByHash', [hash]);
            const receipt = await this.rpcCall('eth_getTransactionReceipt', [hash]);
            
            if (!tx) {
                throw new Error('Transaction not found');
            }
            
            const value = parseInt(tx.value || '0x0', 16) / 1e18;
            const gasPrice = parseInt(tx.gasPrice || '0x0', 16) / 1e9;
            const gasUsed = receipt ? parseInt(receipt.gasUsed, 16) : 'N/A';
            const status = receipt ? (parseInt(receipt.status, 16) === 1 ? 'Success' : 'Failed') : 'Pending';
            
            this.displayResult({
                type: 'Transaction',
                title: `Transaction: ${this.shortenHash(hash)}`,
                data: [
                    { label: 'Hash', value: hash },
                    { label: 'Status', value: status },
                    { label: 'Block Number', value: tx.blockNumber ? parseInt(tx.blockNumber, 16) : 'Pending' },
                    { label: 'From', value: tx.from },
                    { label: 'To', value: tx.to || 'Contract Creation' },
                    { label: 'Value', value: `${value.toLocaleString()} ZSNAIL` },
                    { label: 'Gas Price', value: `${gasPrice.toFixed(2)} Gwei` },
                    { label: 'Gas Used', value: gasUsed.toLocaleString ? gasUsed.toLocaleString() : gasUsed },
                    { label: 'Nonce', value: parseInt(tx.nonce, 16) }
                ]
            });
        } catch (error) {
            throw new Error('Transaction not found');
        }
    }

    displayResult(result) {
        const resultDiv = document.getElementById('searchResults') || this.createResultsDiv();
        resultDiv.innerHTML = `
            <div class="card mt-4">
                <div class="card-header">
                    <h5><i class="fas fa-search-plus"></i> ${result.title}</h5>
                </div>
                <div class="card-body">
                    <div class="table-responsive">
                        <table class="table table-bordered">
                            ${result.data.map(item => `
                                <tr>
                                    <td><strong>${item.label}</strong></td>
                                    <td><code>${item.value}</code></td>
                                </tr>
                            `).join('')}
                        </table>
                    </div>
                </div>
            </div>
        `;
        resultDiv.scrollIntoView({ behavior: 'smooth' });
    }

    createResultsDiv() {
        const container = document.querySelector('.container');
        const resultDiv = document.createElement('div');
        resultDiv.id = 'searchResults';
        container.appendChild(resultDiv);
        return resultDiv;
    }

    showLoading() {
        document.body.style.cursor = 'wait';
    }

    hideLoading() {
        document.body.style.cursor = 'default';
    }

    showError(message) {
        const alertDiv = document.createElement('div');
        alertDiv.className = 'alert alert-danger alert-dismissible fade show mt-3';
        alertDiv.innerHTML = `
            ${message}
            <button type="button" class="btn-close" data-bs-dismiss="alert"></button>
        `;
        document.querySelector('.container').insertBefore(alertDiv, document.querySelector('.container').firstChild);
        setTimeout(() => alertDiv.remove(), 5000);
    }

    updateElement(id, value) {
        const element = document.getElementById(id);
        if (element) element.textContent = value;
    }

    shortenAddress(address) {
        if (!address) return 'N/A';
        return `${address.slice(0, 6)}...${address.slice(-4)}`;
    }

    shortenHash(hash) {
        if (!hash) return 'N/A';
        return `${hash.slice(0, 10)}...${hash.slice(-8)}`;
    }

    formatTimestamp(timestamp) {
        return new Date(timestamp).toLocaleTimeString();
    }

    startAutoRefresh() {
        this.refreshInterval = setInterval(() => {
            this.loadNetworkStats();
            this.loadLatestBlocks();
        }, 30000);
    }

    stopAutoRefresh() {
        if (this.refreshInterval) {
            clearInterval(this.refreshInterval);
        }
    }
}

// Initialize the app when DOM is loaded
document.addEventListener('DOMContentLoaded', () => {
    const app = new ZSnailScanApp();
    
    // Make functions globally accessible for onclick events
    window.searchBlock = (blockNumber) => {
        document.getElementById('searchInput').value = blockNumber.toString();
        app.performSearch();
    };
    
    window.performSearch = () => app.performSearch();
});