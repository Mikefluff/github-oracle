//Author: Ricardo Guilherme Schmidt <3esmit@gmail.com>
pragma solidity ^0.4.11;

import "GitHubAPIReg.sol";
import "NameRegistry.sol";
import "GitRepository.sol";

contract GitHubRepositoryReg is NameRegistry, GitHubAPIReg {

    mapping (uint256 => Repository) repositories; 

    event UpdatedRepository(address addr, uint256 projectId, string full_name, string default_branch);
    
    struct Repository {
        address addr; 
        string full_name;
        string branch; 
    }

    function GitHubRepositoryReg(){
        oraclize_setProof(proofType_TLSNotary | proofStorage_IPFS);
    }
    
    function setRepository(string _repository, bool create) payable only_owner{
       oraclize_query("URL", getQuery(_repository), create? 4000000 : 1000000);
    }

    function getAddr(uint256 _id) public constant returns(address addr) {
        return repositories[_id].addr;
    }

     function getName(address _addr) public constant returns(string name){
        return repositories[indexes[sha3(_addr)]].login;
    } 

    function getAddr(string _name) public constant returns(address addr) {
        return repositories[indexes[sha3(_name)]].addr;
    }

    //oraclize response callback
    function __callback(bytes32 myid, string result, bytes proof) {
        OracleEvent(myid,result,proof);
        if (msg.sender != oraclize.cbAddress()){
          throw;  
        }else {
            _setRepository(myid, result);
        }
    }

    function _setRepository(bytes32 myid, string result) internal //[85743750, "ethereans/TheEtherian", "master"]
    {
        bytes memory v = bytes(result);
        uint8 pos = 0;
        string memory temp;
        uint256 projectId; 
        (projectId,pos) = getNextUInt(v,pos);
        string memory full_name;
        (full_name,pos) = getNextString(v,pos);
        string memory default_branch;
        (default_branch,pos) = getNextString(v,pos);
        address repoAddr = repositories[projectId].addr;
        if(repoAddr == 0x0){   
            repoAddr = address(GitFactory.newGitRepository(projectId, full_name, default_branch));
            indexes[sha3(repoAddr)] = projectId; 
            indexes[sha3(full_name)] = projectId;
            NewRepository(repoAddr, projectId, full_name, default_branch);            
            repositories[projectId] = Repository(addr: repoAddr, full_name: full_name, default_branch: default_branch);|
        }else{
            bytes32 _new = sha3(full_name);
            bytes32 _old = sha3(repositories[projectId].full_name);
            if(_new != _old){
                _updateIndex(_old, _new);
            }
        }
    }
    //internal helper functions
    function _getQuery(string _repository) internal constant returns (string){
        return strConcat("json(https://api.github.com/repos/",_repository,credentials,").$.id,full_name,default_branch");
    }

}