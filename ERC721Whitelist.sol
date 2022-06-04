// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

// This contract does not currently support a public sale. However, this requirement is likely to change.
contract ERC721Whitelist is ERC721Enumerable, Ownable {

  using SafeMath for uint256;
  using Strings for uint256;
  // CONTRACT VARIABLES
  uint256 public price = 0 ether; // this is so the contract is easy to test. Must be changed for mainnet.
  // SUPPLY VARIABLES
  uint256 public nftSupply = 0;
  uint256 mintCap = 0;

  // FEATURE GATES
  bool public presale;
  bool public publicSale;

  string tokenBaseURI;
  // WHITELIST MAPPING
  mapping(address => uint256) _whitelist;

  constructor(string memory baseURI) ERC721("TOKEN NAME","TOKEN TICKER") {
    setBaseURI(baseURI);
  }

  function tokenURI(uint256 tokenId) public view override returns (string memory) {
    require(tokenId < totalSupply(), "Token does not exist.");
    return string(abi.encodePacked(tokenBaseURI, tokenId.toString()));
  }

  function buyWhitelisted(uint256 num) public payable {
    uint256 supply = totalSupply();
    uint256 userAllocation = _whitelist[msg.sender];

    require(presale, "Pre-sale must be active to buy a whitelisted NFT.");
    require(num <= userAllocation, "User must be part of whitelist.");
    require(supply + num <= nftSupply, "Can't mint more than total whitelist supply."); 
    require(msg.value >= price.mul(num), "Incorrect amount of ether sent.");

    _whitelist[msg.sender] = userAllocation - num;

    for(uint256 i; i < num; i++) {
      uint256 tokenId = supply + i;
      _safeMint(msg.sender, tokenId);
    }
  }

  function airdrop(address recvAddr, uint256 num) public onlyOwner {
    uint256 supply = totalSupply();
    require(supply + num <= nftSupply, "Airdrop has expired.");
    for (uint256 i; i < num; i++) {
        _safeMint(recvAddr, supply + i);
    }
  }

  function buyNFT(uint256 num) public payable {
    uint256 supply = totalSupply();

    require(publicSale, "Public sale must be active to buy a NFT.");
    require(num <= mintCap, "Cannot exceed mint cap (4)");
    require(supply + num <= nftSupply, "Can't mint more than total supply."); // starts at 0.
    require(msg.value >= price.mul(num), "Incorrect amount of ether sent.");

    for(uint256 i; i < num; i++) {
      uint256 tokenId = supply + i;
      _safeMint(msg.sender, tokenId);
    }
  }

  function togglePresale() public onlyOwner {
    presale = !presale;
  }

  function togglePublicSale() public onlyOwner {
    publicSale = !publicSale;
  }

  function withdrawFunds(address vault) public payable onlyOwner {
    require(payable(vault).send(address(this).balance));
  }

// whitelist supply is wrong variable to iterate on here.
  function setWhitelist(address[] calldata addresses, uint256[] calldata amount, uint256 whitelistedNum) external onlyOwner {
    for(uint256 i = 0; i < whitelistedNum; i++) {
      _whitelist[addresses[i]] = amount[i];
    }
  }

  function setBaseURI(string memory baseURI) public onlyOwner {
    tokenBaseURI = baseURI;
  }

  function remaining(address addr) view public returns (uint256) {
    return _whitelist[addr];
  }

  function tokensOfOwner(address tokenOwner) external view returns(uint256[] memory) {
    uint256 tokenCount = balanceOf(tokenOwner);
    if (tokenCount == 0) {
      return new uint256[](0);
    } else {
      uint256[] memory tokensOwned = new uint256[](tokenCount);
      for(uint256 i; i < tokenCount; i++) {
        tokensOwned[i] = tokenOfOwnerByIndex(tokenOwner, i);
      }

      return tokensOwned;
    }
  }

  function setPrice(uint256 newPrice) public onlyOwner {
    price = newPrice;
  }
}
