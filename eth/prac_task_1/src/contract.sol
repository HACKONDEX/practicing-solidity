pragma solidity  >=0.8.0;

contract UniversityAdmission {
    struct Student {
        string name;
        uint age;
    }

    struct Group {
        uint[] studentIds;
    }

    Student[] students;
    // There will be only 23 groups
    uint groupsCount = 23;
    Group[23] groups;


    function _randomGroupNumber(string memory _name) private view returns (uint) {
        uint rand = uint(keccak256(abi.encodePacked(_name)));
        return rand % groupsCount;
    }

    function admitStudent(string memory _name, uint _age) public {
        uint studentId = students.length;
        students.push(Student(_name, _age));

        uint groupId = _randomGroupNumber(_name);
        groups[groupId].studentIds.push(studentId);
    }

}