# 🔐 DaVinciGraph NFT Locker V2

<div align="center">
  <img src="DAVINCI.png" alt="DaVinciGraph Logo" width="200"/>
  <h3>Lock Your NFTs Safely on Hedera</h3>
  <p>Contract ID: <a href="https://hashscan.io/mainnet/contract/0.0.8215501">0.0.8215501</a></p>
</div>

## 🎯 What is NFT Locker?

A secure way to lock your NFTs for a specific time period. Ideal for controlled NFT distribution and ensuring that team or special edition NFTs are transferred only when intended.

## 🎮 How to Use It?

1. **Lock Your NFT**

   - Choose the NFT you wish to lock.
   - Specify the beneficiary who will receive the NFT when the lock period ends.
   - Set the lock duration.

2. **During the Lock**

   - Only the beneficiary can extend the lock duration.
   - All lock details are publicly viewable.

3. **When Lock Ends**
   - Anyone can trigger the withdrawal
   - Only the beneficiary account will receive the NFT

## 💰 Fees

- All fees are paid in DAVINCI tokens
- Maximum fee: 200 DAVINCI
- Fee structure:
  - Creating a new lock: 50 DAVINCI
  - Extending lock duration: 50 DAVINCI
- No fees for:
  - Withdrawing unlocked NFT
  - Checking lock information
  - Token association operations
- Some accounts can be fee-exempt

## ✅ What Can You Lock?

- Hedera NFTs (excluding those with royalties and fallback fees).

## ❌ What Can't You Lock?

- NFTs with royalties and fallback fees.
- Multiple NFTs in one lock (each NFT requires an individual lock).

## 👥 Who's Who?

- **Creator**: Person who creates and sets up the lock
- **Beneficiary**: Person who receives and withdraws NFT
  can be the Creator or different people!

## 🔑 Lock Control

- **Beneficiary can:**

  - Extend the lock duration
  - Withdraw NFT after lock ends

## 🤝 Need Help?

- Visit [DaVinciGraph](https://davincigraph.io)
- Join [Discord](https://discord.gg/dGvkBmQGt9)
- Follow us on [X](https://x.com/davincigraph)

<div align="center">
  <p>Built with ❤️ by DaVinciGraph</p>
</div>
