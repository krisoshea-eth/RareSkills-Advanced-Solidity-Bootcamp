ERC721A optimizes the gas usage, particularly when minting multiple tokens, through several mechanisms, which can significantly lower the costs when compared to the standard ERC721 contract. 

Lazy Minting: ERC721A employs a kind of lazy minting, which means gas is only used when it's absolutely necessary. This is particularly beneficial during the minting process, helping to avoid gas wars when many people want to mint at the same time. If a collection ceases to exist, the gas will be saved indefinitely​1​.

Optimized Gas Spending: ERC721A is designed to optimize gas spending, allowing the minting of multiple tokens for nearly the price of minting a single token. This is a marked improvement over the more popular implementation of ERC721, known as ERC721Enumerable from OpenZeppelin​2​​.

Code Optimization: Removal of redundant lines of code is one of the optimizations ERC721A implements to reduce gas fees. By streamlining the code, the gas required for minting multiple NFTs is significantly reduced, essentially making the cost of minting multiple NFTs comparable to minting a single NFT​​.

Batch Minting: One of the main features of ERC721A is its ability to mint multiple NFTs in a single transaction, which results in substantial gas savings. This is achieved through the implementation of IERC721, enabling the minting of multiple NFTs for essentially the same cost as minting a single one​​. In essence, ERC721A allows for the efficient creation of multiple NFTs in a single transaction, which is a primary factor in saving gas fees. In the standard ERC721 contract, minting each token requires a separate transaction, each incurring its gas fee. In contrast, ERC721A enables batch minting, which amortizes the gas cost over multiple tokens, thus reducing the per-token gas fee​. When minting 5 NFTs at a time, ERC721A used 106,891 gas compared to the 531,708 gas used in a standard ERC721 contract, highlighting a significant reduction in gas usage​. A detailed comparison on gas usage for minting multiple NFTs showed that with ERC721A, the gas cost increases by about 2k gas per extra mint, while with the standard ERC721, it increases by about 115k gas per extra mint​.

Restriction on Maximum Number of Tokens: ERC721A achieves gas savings mostly through restricting the maximum number of tokens from 2^256 to 2^64. This limitation helps in reducing the gas required for certain operations​.

ERC721A makes a few assumptions to reduce gas costs significantly:
    1: Token IDs should always increment consecutively starting from 0.
    2: Reducing the gas costs of minting NFTs is prioritized over optimizing any other ERC721 calls.
With these assumptions, ERC721A implements the following optimizations:
    1: It reduces wasted storage of token metadata.
    2: It limits ownership state updates to only once per batch mint, instead of once per minted NFT​.

However, ERC721A adds cost in several ways:

Computational Overhead: ERC721A adds a computational overhead of 2k gas per minted token, which is a small price to pay for the significant gas savings it provides​. This is due to the fact that ERC721A uses a mapping to store the owner of each token, which is more expensive than the array used in the standard ERC721 contract​. This is a trade-off that ERC721A makes to reduce the gas costs of minting NFTs. 

Transfer Costs: ERC721A adds a transfer cost of 5k gas per minted token. This is due to the fact that ERC721A uses a mapping to store the owner of each token, which is more expensive than the array used in the standard ERC721 contract​.

ERC721A enumerable's implementation should not be used on chain for the following reasons:

Redundant Storage: The widely-used OpenZeppelin (OZ) implementation of IERC721Enumerable includes redundant storage of each token’s metadata. This approach optimizes for read functions at a significant cost to write functions. The denormalized structure isn't ideal since users are much less likely to pay for read functions, and this design leads to higher gas costs for write operations​​.

Gas Overhead: The primary concern with implementing enumerable features on-chain, as seen with ERC721Enumerable, is the significant gas overhead. On-chain enumeration requires additional data management, which increases the gas costs for minting and transferring tokens due to the extra data storage and manipulation required to maintain the enumerability information​1.The IERC721Enumerable extension, which allows for on-chain enumeration of tokens, is often avoided due to the large gas overhead it requires. This overhead makes it less gas-efficient, which can be a concern in environments where minimizing gas costs is a priority​​.

Gas Intensive Enumeration Functions: The functions handling enumerations are described as the most gas-intensive portion of the ERC721 standard. Depending on the specific requirements of your DApp, the gas costs associated with these enumeration functions might not be justified​​.

Unnecessary Operations: The ERC721Enumerable extension does a lot of unnecessary operations which drive up the gas cost of mint functions significantly, potentially costing the community millions of dollars. This implies that the enumerable functionality could introduce additional, perhaps unjustifiable, gas costs​​.

Sequential Token IDs: ERC721A requires that token IDs be sequential. This design choice is part of what enables ERC721A to save gas during minting operations, especially in bulk. However, this requirement might not be compatible with on-chain enumeration features that may require additional data management and could potentially increase gas costs, offsetting the gas savings achieved by ERC721A​2.

Reduced Metadata Storage: ERC721A also optimizes contracts by reducing unused space, which is used to store metadata from tokens, and limits ownership to one coin from the entire NFT batch. These optimizations could be compromised or become less effective with an on-chain enumerable implementation, which might require additional data storage and management​2​.

While enumerability can provide useful functionalities, its implementation on-chain can significantly increase gas costs, especially for write operations. This trade-off between additional functionality and gas efficiency is a key consideration when deciding whether to use an enumerable implementation on-chain.

The guidance provided in one of the sources is that unless there's a strong need to know the list of tokens belonging to a specific address on-chain (which is what ERC721Enumerable facilitates), it's better to avoid using ERC721Enumerable and by extension, any enumerable implementation that would be crafted for ERC721A, as it would likely introduce similar gas overheads due to the additional data management required for enumerability​. In summary, the core design of ERC721A aims at optimizing gas costs during minting, and introducing on-chain enumeration akin to ERC721Enumerable's implementation could potentially offset these gas savings and introduce additional complexities and costs. Therefore, unless the on-chain enumeration is crucial for a project, it's advisable to avoid implementing such features on-chain for ERC721A contracts.