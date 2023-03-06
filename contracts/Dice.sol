// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.9;

abstract contract Dice {
    struct Die {
        uint256[] values;
        string name;
    }

    struct ValueLabel {
        uint256 value;
        string label;
    }
    // Mapping from dice name => ...
    mapping(string => bool) public nameExists;
    mapping(string => Die) public dice;
    // from dice name => ... => ...
    //// label => value
    mapping(string => mapping(string => uint256)) public dieValues;
    //// value => label
    mapping(string => mapping(uint256 => string)) public dieLabels;

    string[] _dice;

    function createMappedDie(Die memory die, string[] memory labels) internal {
        require(
            die.values.length == labels.length,
            "label length does not match values length"
        );
        require(!nameExists[die.name], "die name must be unique");
        for (uint256 i = 0; i < labels.length; i++) {
            dieValues[die.name][labels[i]] = die.values[i];
            dieLabels[die.name][die.values[i]] = labels[i];
        }
        dice[die.name] = die;
        nameExists[die.name] = true;
        _dice.push(die.name);
    }

    function getAllDice() public view returns (Die[] memory allDice) {
        allDice = new Die[](_dice.length);
        for (uint256 i = 0; i < _dice.length; i++) {
            allDice[i] = dice[_dice[i]];
        }
    }

    function labelsForValues(uint256[] memory values, string memory dieName)
        public
        view
        returns (ValueLabel[] memory mappings, string[] memory labels)
    {
        mappings = new ValueLabel[](values.length);
        labels = new string[](values.length);
        for (uint256 i = 0; i < values.length; i++) {
            mappings[i] = ValueLabel({
                value: values[i],
                label: dieLabels[dieName][values[i]]
            });
            labels[i] = dieLabels[dieName][values[i]];
        }
    }
}
