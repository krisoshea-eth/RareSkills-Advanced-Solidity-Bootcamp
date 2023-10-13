// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "@openzeppelin/contracts@5.0.0/contracts/token/ERC721/extensions/IERC721Enumerable.sol";
import "@openzeppelin/contracts@5.0.0/contracts/access/Ownable2Step.sol";

contract QueryNft is Ownable2Step {
    IERC721Enumerable public NftEnumerable;

    // Mapping to store whether each tokenId is prime
    mapping(uint256 => bool) public isPrimeMapping;

    // Events
    event PrimeStatusUpdated(uint256 tokenId, bool isPrime);
    event NumOfPrimeTokenIdsQueried(address user, uint256 count);

    constructor(IERC721Enumerable _NftEnumerable) {
        NftEnumerable = _NftEnumerable;
    }

    function numOfPrimeTokenIds(address user) external view returns (uint256 primeCounter) {
        uint256 NftBalance = NftEnumerable.balanceOf(user);
        uint256 primeCounter = 0;
        uint256 tokenId;
        for (uint256 i = 0; i < NftBalance; ++i) {
            tokenId = NftEnumerable.tokenOfOwnerByIndex(user, i);
            if (isPrimeMapping[tokenId]) {
                primeCounter += 1;
            }
        }
        emit NumOfPrimeTokenIdsQueried(user, primeCounter); // Emit event
        return primeCounter;
    }

    function updatePrimeMapping(uint256 tokenId) external onlyOwner {
        if (isPrimeMapping[tokenId] == false) {
            bool isPrime = checkPrime(tokenId);
            isPrimeMapping[tokenId] = isPrime;
            emit PrimeStatusUpdated(tokenId, isPrime); // Emit event
        }
    }

    function checkPrime(uint256 tokenId) internal pure returns (bool) {
        return (tokenId != 0 && tokenId != 1 && (tokenId == 2 || (tokenId % 2 != 0 && _isPrime(tokenId))));
    }

    function _isPrime(uint256 number) internal pure returns (bool) {
        if (number < 4) return false; // 0, 1, and 2 are handled in checkPrime
        if (number % 2 == 0) return false; // Check divisibility by 2 outside the loop
        for (uint256 i = 3; i <= sqrt(number); i += 2) {
            if (number % i == 0) return false; // if number is divisible by i, it's not prime
        }
        return true; // if no divisors found, it's prime
    }

    function sqrt(uint256 x) internal pure returns (uint256) {
        if (x == 0) return 0;
        uint256 z = (x + 1) / 2;
        uint256 y = x;
        while (z < y) {
            y = z;
            z = (x / z + z) / 2;
        }
        return y;
    }
}
