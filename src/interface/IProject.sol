pragma solidity ^0.8.0;

interface IProject {
    struct IDOProject {
        address owner;
        uint256 price;
        uint256 min;
        uint256 max;
        uint256 timeEnd;
        uint256 tokenTotal;
    }
    event EVENTAddIDOProject(address indexed tokenCA, IDOProject idoproject);
    event EVENTPreSale(
        address indexed tokenCA,
        address indexed user,
        uint256 amount
    );
    event EVENTIDOProjectRefund(
        address indexed tokenCA,
        address indexed user,
        uint256 amount
    );
    event EVENTIDOProjectClaim(
        address indexed tokenCA,
        address indexed user,
        uint256 amount
    );

    error ErrorProjectExisted(address tokenCA);
    error ErrorProjectWrongAmount(address tokenCA);
    error ErrorProjectTimeEnded(address tokenCA);
    error ErrorExceedingAmount(uint256 amount);
    error ErrorIDOProjectStill(address tokenCA);
    error ErrorIDOProjectCannotRefund(address tokenCA);
    error ErrorNothingCanRefund(address tokenCA);
    error ErrorTimeNotEnd(address tokenCA);
    error ErrorProjectFailed(uint256 minimalGoal,uint256 amount);
}
