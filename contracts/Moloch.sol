pragma solidity ^0.4.0;

import 'zeppelin-solidity/contracts/ownership/Ownable.sol';
import 'zeppelin-solidity/contracts/math/SafeMath.sol';
import 'zeppelin-solidity/contracts/token/ERC20/ERC20.sol';
import './VotingShares.sol';
import './MemberApplicationBallot.sol';

contract Moloch is Ownable {
  using SafeMath for uint256;

  struct Member {
    bool approved;
    uint256 votingShares;
    uint256 ethTributeAmount;
    // token tribute
    address tokenTributeAddress;
    uint256 tokenTributeAmount;
    address ballotAddress;
  }

  address[] public approvedMembers;

  mapping (address => Member) public members;
  address public votingSharesAddr;

  event MemberApplied(
    address indexed memberAddress,
    uint256 votingSharesRequested,
    uint256 ethTributeAmount,
    address tokenTributeAddress,
    uint256 tokenTributeAmount,
    address ballotAddress
  );

  event MemberApproved(
    address indexed memberAddress
  );

  modifier onlyMember {
    require(members[msg.sender].approved);
    _;
  }

  function Moloch() {
    votingSharesAddr = new VotingShares();
  }

  // add founding member, auto approved
  function addFoundingMember(
    address _memberAddress,
    uint256 _votingShares,
    address _tokenTributeAddress,
    uint256 _tokenTributeAmount
  ) public payable 
  {
    members[_memberAddress] = Member(
      true, // auto approve
      _votingShares,
      msg.value,
      _tokenTributeAddress,
      _tokenTributeAmount,
      address(0) // no voting ballot
    );
    MemberApproved(_memberAddress);

    approvedMembers.push(_memberAddress);
    // TODO: TRANSFER TO GUILD BANK
  }

  function submitApplication(
    uint256 _votingSharesRequested,
    address _tokenTributeAddress,
    uint256 _tokenTributeAmount
  ) public payable 
  {
    // can't reapply if already approved
    require(!members[msg.sender].approved);

    // create ballot for voting new member in
    address ballotAddress = new MemberApplicationBallot(approvedMembers);

    members[msg.sender] = Member({ 
      approved: false,
      votingShares: _votingSharesRequested,
      ethTributeAmount: msg.value,
      tokenTributeAddress: _tokenTributeAddress,
      tokenTributeAmount: _tokenTributeAmount,
      ballotAddress: ballotAddress
    });

    MemberApplied(
      msg.sender,
      _votingSharesRequested,
      msg.value,
      _tokenTributeAddress,
      _tokenTributeAmount,
      ballotAddress
    );
  }

  function voteOnMemberApplication(address member, bool accepted) onlyMember {
    require(!members[member].approved);

    MemberApplicationBallot ballot = MemberApplicationBallot(members[member].ballotAddress);
    if (accepted) {
      ballot.voteFor();
    } else {
      ballot.voteAgainst();
    }
  }
}