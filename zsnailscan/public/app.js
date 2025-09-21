// ZSnailScan Frontend JavaScript - Complete Netlify Version
class ZSnailScanApp {
    constructor() {
        this.rpcURL = 'http://34.122.156.185:8545';
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
            const response = await fetch(`${this.rpcURL}/info`);
            if (!response.ok) throw new Error(`HTTP ${response.status}`);
            
            const data = await response.json();
            this.updateElement('latestBlock', data.blockNumber?.toLocaleString() || 'N/A');
            this.updateElement('totalSupply', `${parseFloat(data.totalSupplyZSnail || 0).toLocaleString()} ZSNAIL`);
            this.updateElement('gasPrice', `${(parseInt(data.gasPrice || 0) / 1e9).toFixed(2)} Gwei`);
            this.updateElement('chainId', data.chainId || this.chainId);
            this.updateElement('consensus', data.consensusType || 'Proof of Work');
            this.updateElement('difficulty', data.difficulty || 'N/A');
            this.updateElement('minerAddress', this.shortenAddress(data.minerAddress) || 'N/A');
            this.updateElement('totalBlocks', data.totalBlocks?.toLocaleString() || 'N/A');
            this.updateElement('connectedWallets', data.connectedWallets?.toLocaleString() || 'N/A');
            
            const statusElement = document.getElementById('networkStatus');
            if (statusElement) {
                const isOnline = data.status === 'running';
                statusElement.innerHTML = `<span class="network-indicator ${isOnline ? 'online' : 'offline'}"></span>${isOnline ? 'Online' : 'Offline'}`;
            }
        } catch (error) {
            this.showError('Failed to connect to ZSnail L2 blockchain');
        }
    }

    async loadLatestBlocks() {
        try {
            const response = await fetch(`${this.rpcURL}/explorer`);
            if (!response.ok) throw new Error(`HTTP ${response.status}`);
            
            const data = await response.json();
            const tbody = document.getElementById('latestBlocksTable');
            if (tbody && data.recentBlocks) {
                tbody.innerHTML = data.recentBlocks.map(block => `
                    <tr onclick="this.searchBlock(${block.number})" style="cursor: pointer;">
                        <td><span class="badge bg-primary">${block.number}</span></td>
                        <td><code>${this.shortenHash(block.hash)}</code></td>
                        <td>${block.transactions}</td>
                        <td><code>${this.shortenAddress(block.miner)}</code></td>
                        <td>${this.formatTimestamp(block.timestamp)}</td>
                    </tr>
                `).join('');
            }
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
        const response = await fetch(`${this.rpcURL}/wallet/${address}`);
        if (!response.ok) throw new Error('Wallet not found');
        
        const data = await response.json();
        this.displayResult({
            type: 'Wallet',
            title: `Wallet: ${this.shortenAddress(address)}`,
            data: [
                { label: 'Address', value: address },
                { label: 'Balance', value: `${parseFloat(data.balanceZSnail || 0).toLocaleString()} ZSNAIL` },
                { label: 'Nonce', value: data.nonce || 0 },
                { label: 'Type', value: data.type || 'Standard' },
                { label: 'Is Miner', value: data.isMiner ? 'Yes' : 'No' }
            ]
        });
    }

    async searchBlock(blockNumber) {
        const response = await fetch(`${this.rpcURL}/explorer/block/${blockNumber}`);
        if (!response.ok) throw new Error('Block not found');
        
        const data = await response.json();
        this.displayResult({
            type: 'Block',
            title: `Block #${blockNumber}`,
            data: [
                { label: 'Hash', value: data.hash },
                { label: 'Parent Hash', value: data.parentHash },
                { label: 'Miner', value: data.miner },
                { label: 'Timestamp', value: new Date(data.timestamp).toLocaleString() },
                { label: 'Transactions', value: data.transactions?.length || 0 },
                { label: 'Difficulty', value: data.difficulty },
                { label: 'Nonce', value: data.nonce },
                { label: 'Gas Used', value: data.gasUsed },
                { label: 'Gas Limit', value: data.gasLimit }
            ]
        });
    }

    async searchTransaction(hash) {
        this.showError('Transaction search not yet implemented');
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
    new ZSnailScanApp();
});