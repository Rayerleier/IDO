pragma solidity ^0.8.0;

import "./RAINToken.sol";
import "./interface/IProject.sol";
import "../lib/openzeppelin-contracts/contracts/token/ERC20/extensions/ERC20Permit.sol";

contract IDO is IProject {
    mapping(address => IDOProject) IDOProjectList;
    mapping(address => mapping(address => uint256)) IDOProjectLedger;
    mapping(address => uint256) IDOProjectAmount;

    RAINToken token;
    constructor() {}

    function IDOProjectOf(address tokenCA)external view returns(IDOProject memory){
        return IDOProjectList[tokenCA];
    }

    function IDOProjectLedgerOf(address tokenCA, address user) external view returns(uint256) {
        return IDOProjectLedger[tokenCA][user];
    }

    function IDOProjectAmountOf(address tokenCA)external view returns(uint256) {
        return IDOProjectAmount[tokenCA];
    }

    function addIDOProject(
        address tokenCA,
        IDOProject memory _idoproject
    ) external {
        _addIDOProject(tokenCA, _idoproject);
    }

    function _addIDOProject(
        address tokenCA,
        IDOProject memory _idoproject
    ) internal {
        if (IDOProjectList[tokenCA].timeEnd != 0) {
            revert ErrorProjectExisted(tokenCA);
        }
        if (_idoproject.max * _idoproject.price != _idoproject.tokenTotal) {
            revert ErrorProjectWrongAmount(tokenCA);
        }
        ERC20Permit(tokenCA).transferFrom(
            msg.sender,
            address(this),
            _idoproject.tokenTotal
        );
        _idoproject.owner = msg.sender;
        IDOProjectList[tokenCA] = _idoproject;
        emit EVENTAddIDOProject(tokenCA, _idoproject);
    }

    function preSale(address tokenCA) external payable {
        _preSale(tokenCA);
    }

    function _preSale(address tokenCA) internal {
        IDOProject memory _project = IDOProjectList[tokenCA];
        if (_project.timeEnd < block.timestamp)
            revert ErrorProjectTimeEnded(tokenCA);
        if (IDOProjectAmount[tokenCA] + msg.value > _project.tokenTotal)
            revert ErrorExceedingAmount(msg.value);
        IDOProjectAmount[tokenCA] += msg.value;
        IDOProjectLedger[tokenCA][msg.sender] += msg.value;
        emit EVENTPreSale(tokenCA, msg.sender, msg.value);
    }

    function refund(address tokenCA) external {
        _refund(tokenCA);
    }

    function _refund(address tokenCA) internal {
        IDOProject memory _project = IDOProjectList[tokenCA];
        if (block.timestamp < _project.timeEnd)
            revert ErrorIDOProjectStill(tokenCA);
        if (_project.min*_project.price < IDOProjectAmount[tokenCA])
            revert ErrorIDOProjectCannotRefund(tokenCA);
        if (msg.sender == _project.owner) {
            ERC20Permit(tokenCA).transferFrom(
                address(this),
                msg.sender,
                _project.tokenTotal
            );
            emit EVENTIDOProjectRefund(
                address(this),
                msg.sender,
                _project.tokenTotal
            );
        } else {
            uint256 refundAmount = IDOProjectLedger[tokenCA][msg.sender];
            if (refundAmount == 0) revert ErrorNothingCanRefund(tokenCA);
            IDOProjectLedger[tokenCA][msg.sender] = 0;
            IDOProjectAmount[tokenCA] -= refundAmount;
            (bool success, ) = address(msg.sender).call{value: refundAmount}(
                ""
            );
            require(success, "Transfer Failed.");
            emit EVENTIDOProjectRefund(address(this), msg.sender, refundAmount);
        }
    }

    function claim(address tokenCA) external {
        _claim(tokenCA);
    }

    function _claim(address tokenCA) internal {
        IDOProject memory _project = IDOProjectList[tokenCA];
        if (_project.timeEnd > block.timestamp) revert ErrorTimeNotEnd(tokenCA);
        if (_project.min * _project.price > IDOProjectAmount[tokenCA])
            revert ErrorProjectFailed(_project.min * _project.price,IDOProjectAmount[tokenCA]);
        if(_project.owner == msg.sender){
            uint256 claimOut = IDOProjectAmount[tokenCA];
            (bool success,) = address(msg.sender).call{value:claimOut}("");
            require(success, "Transfer Failed.");
            emit EVENTIDOProjectClaim(tokenCA, msg.sender, claimOut);
        }else{
            uint256 refundAmount = IDOProjectLedger[tokenCA][msg.sender];
            IDOProjectLedger[tokenCA][msg.sender] = 0;
            ERC20Permit(tokenCA).transfer( msg.sender, refundAmount/_project.price);
            emit EVENTIDOProjectClaim(tokenCA, msg.sender, refundAmount);
        }
    }
}
