# VOTE CONTRACT

**1.  Introduction**

Bounties, competitions, hackathons are big components of how Kambria will drive open innovation in different verticals. We call these components Projects. We created KambriaVote, an on-chain voting mechanism based on Carbonvote to let the Kambria community be involved in various aspects of running projects.
The purpose of this wiki is to document the technical specification of how KambriaVote is implemented. It will be improved over time when we extend the KambriaVote to support more complex Voting Mechanism.

**2. Voting Mechanism**

**2.1 Usecase**
- As KAT token holder, the user can join any open campaign and vote for ONE project inside that campaign.
- When decided, the user can cast all the balance of KATT in their account as votes (the system only track the balance of KAT and count as Vote, no KAT or ETH is transfer out of user wallet when they vote). If the user votes another project of the same campaign, the system will move all votes of that user over to that project.

**2.2 How votes are counted**

The vote count statistics will dynamically reflect the current number of KAT count of the users who vote for a specific project. At the end of the voting period, the balance of KAT in user account will be counted towards the total votes. E.g. if a user owns 10 KAT when he/she first voted but spent 2 KAT, at the end of the voting period he/she will only contribute 8 votes (remaining balance) to that desired project. It will ensure the "double-vote" trick is disable.

**3. Technical Implementation**

**3.1 Sequence diagram of the implemented logic**

![Contracts Relationship.png](https://trello-attachments.s3.amazonaws.com/5ae9679473ca8f145caaf6ca/5af081a93fdca7a8845d196b/bc7441dcf4e82fec76472a33e671a978/Contracts_Relationship.png "Contracts Relationship")

*Figure 1: Contracts Relationship.*

![Use Flow.png](https://trello-attachments.s3.amazonaws.com/5ae9679473ca8f145caaf6ca/5af081a93fdca7a8845d196b/93ecd47e1b3529385fccdc13ede29763/Use_Flow.png "Use Flow")

*Figure 2: Use Flow.*

**3.2 Moderator SmartContract**

Moderator is a one-time-deployed smart contract. With the moderator, Kambria has the capability to manage and publish all of voting campaigns (called ballot) inexpensively.

To operate the moderator, you must have privilege that securely based on Transaction and SmartContract mechanism of Ethereum.

**3.3 Ballot SmartContract**

Ballot is a smart contract that represents for single voting campaign, so with many campaigns, we need multiple ballot contracts. A ballot is deployed by the moderator with inputs.
- MODERATOR: the moderator address.
- RATE: 10^RATE is the basic unit to make a vote.
- CIDS: standing for candidate identities that is a list of candidate id.

Some extra variables:
- START: the block number at starting.
- END: the block number at the end.
- SCID: the index of candidate id in CIDS list. (a temporary terminology)

Vote is a action that you give your voting-paper to one and only one candidate by letting ballot contract know the SCID. Your power of voting paper is based on your balance of KAT.

Kambria voting system prefer using a traditional transaction to a interating-smartcontract transaction because it's hard to make every voters know how to construct a interacting-smartcontract transaction or force them to use Kambria voting web page with previously constructed supports. With using the traditional transaction, voters simply make a vote by making a transfer ETH transaction to ballot by using any wallet they want but no-ETH will be collected.

To vote, voters have to send a transaction to ballot address with a number of WEI that represent SBID they decided to vote for.

- 1 ETH = 10^18 WEI

- a number of WEI = SCID * 10^RATE

***NOTICE THAT YOUR ETH WILL BE REFUNDED IMMEDIATELY.***

For example:

I want to vote for the candidate X with **SCID = 3** in a campaign at ballot address **0xef75e34c50c1b109fe65ee696f12225de508b9f2** with **RATE = 12**. Then I create a transaction sending **3 * 10^12 WEI = 0.000003 ETH** to 0xef75e34c50c1b109fe65ee696f12225de508b9f2. The only one thing I have to pay is a fee transaction, my ETH and KAT are still safe in my wallet. 

The code:

    function() payable mustBeVoting {
        uint256 value = msg.value;
        msg.sender.transfer(msg.value);

        uint256 vote = value.div(RATE);
        require(vote >= 0 && vote < CANDIDATE_IDENTITIES.length);
        votes[msg.sender] = CANDIDATE_IDENTITIES[vote];
        emit VoteFor(msg.sender, votes[msg.sender]);
    }

As you can see in the code above, `msg.sender.transfer(msg.value)` is the line of code to refund you ETH, the remainder is calculate the SCID from you and record it into a mapping `votes[msg.sender] = CANDIDATE_IDENTITIES[vote]`.

Because of mapping being used to record the vote of an address, voter with one address can vote for only one candidate in a ballot but multiple candidates in multiple ballots, make sense.

To change your vote, you just send another transaction with your new vote, the old one will be deprecated and be replaced by the new one.

It's also possible to make an un-vote which means you decide to revoke your vote. Having 2 ways to do that. First one is you transfer all your KAT to another address that did not vote, so you can understand that you vote now is still there but have zero-power. Second one is send a vote with **SCID = 0**. In default, we usually save **CID = 0x** in CIDS and it corresponds with no-project, so you can send a transaction along with zero-ETH to un-vote. However be careful, in some special case, it will be changed so you need to check that before hand.

Vote can do by a transfer transaction but doesn't mean you can vote/un-vote whenever you want. The `mustBeVoting` condition helps us to make sure it's just possible to vote/un-vote when the ballot is not finished yet.

And to end or restart a ballot, it simply assign `END` to current block number or 0 respectively. The moderator is the only one has privilege to call those functions and that how The moderator be as a manager of all ballots.

**4. Kambria Vote vs Carbon Vote**

**4.1 Security**

In Carbon vote, it does not have moderator definition. Every time starting a new ballot, Vote contract must be manually deployed for every single candidate. For instance, you want to create a campaign with 10 candidates so you must deploy 10 contracts onto Ethereum network.

Without the moderator, Carbon vote cannot group those candidates into a campaign or a ballot, and further, impossible to map those candidates to components in the real world, by itself. To resolve all of things like that, at least, we/they need to create a centralized machine that track the relationship of **{Ballot, Candidate, Real-Component}** (called BCR relationship) (In our case, Real-Component might be the projects)

Because of centralization, Carbon vote face to the risk of hack or cheating on the result by destroying the BCR relationship.

In Kambria vote, we putted the BCR relationship onto Ethereum network and it became an on-chain proof that means decentralization.

Under the hood, all candidates of a ballot share a common address which is ballot contract address. By this, we created the part **{Ballot, Candidate}** of the BCR relationship. In some sections above, we got familiar with CID definition, brief of candidate identity. So, How is CID created? It's still not finalized but the current idea that CID is a hash (SHA256) of KDNA. By using hash, we can satisfy the prerequisite that CID is unique, and then we can construct the remainder of relationship is **{Candidate, Real-Component}**.

Let's imagine that you want to make an attack to Kambria Vote by trying to destroy BCR relationship. We consider the first part **{Ballot, Candidate}**, because it was putted on blockchain so to destroy it, we must destroy blockchain. Sounds interesting but impossible. Skipping the first part and moving on to the second part **{Candidate, Real-Component}**. This relationship is a cryptography, the hash of KDNA is CID (one-way function). With top-down approach, we must to destroy hash function. Still sounds great, but impossible. With bottom-up approach, we try to change the KDNA, but remember that the moment you change KNDA, CID will be changed as well. Thus, the new **{Candidate, Real-Component}** you just create would be stale.

However, a bunch of solutions will not only help to increase security level but also seems increasing the cost. In order to clarify "Is it actually Kambria more expensive than Carbon?", we move to the next section.

**4.2 Gas used**

In Carbon vote, they used one contract for one candidate so it means multiple contract for a voting campaign. Otherwise, Kambria vote just use only one ballot contract to operate one voting campaign and it help us to cut the deployment fee down.

Let take a look at table below that compare gas-used of a voting campaign by using Carbon and Kambria vote on Rinkeby test-net.

| Action          | Carbon Vote           | Kambria Vote       |
| --------------- |:----------------------|:-------------------|
| Deploy campaign | 108.173 x 5 = 540.865 | 573.043            |
| Vote            | 22.227                | 51.716             |
| Re-vote         | 22.227                | 36.716             |
| Void a vote     | 21.000+               | 21.000+ or 30.016  |

*Table 1: The 5-candidate campaign.*

| Action          | Carbon Vote              | Kambria Vote      |
| --------------- |:-------------------------|:------------------|
| Deploy campaign | 108.173 x 10 = 1.081.730 | 669.786           |
| Vote            | 22.227                   | 51.716            |
| Re-vote         | 22.227                   | 36.716            |
| Void a vote     | 21.000+                  | 21.000+ or 30.016 |

*Table 2: The 10-candidate campaign.*

| Action          | Carbon Vote | Kambria Vote      |
| --------------- |:------------|:------------------|
| Deploy campaign | 108.173 x n | ~ 700.000         |
| Vote            | 22.227      | 51.716            |
| Re-vote         | 22.227      | 36.716            |
| Void a vote     | 21.000+     | 21.000+ or 30.016 |

*Table 3: The n-candidate campaign.*

Considering table 3, We get that whole the fee of Carbon vote is linearly increased by the number candidates, ***O(n)***. But with Kambria vote, the fee is a constant, ***O(1)***.

Generally, Carbon may be good at the campaigns with small number of candidates but in the long term, Kambria is taking advantage.

**4.3 Void a vote**

In case of Carbon vote, to reject your previous vote, you need to move out all of your ETH to another address. That means, your vote still there but now it hold zero-power. It seems to be good and possible for every one but we look over nearly, we will get some problems. With some big company or organization, their wallet will hold a big number of ETH and most of them secure it by using a multi-sig wallet or a cold wallet. Both of them when doing a transaction, it needs 2 people who share the private key at least. So just imagining the process when they have to move to another wallet.

- Step 1: Deploy new multi-sig wallet or a cold wallet.

- Step 2: Calculate and re-share the new private key.

- Step 3: Create a transaction to move ETH to new wallet.

Those steps are quite expensive and took for a while with unpredictable risks. In addition to gas-used, except for 21.000 gas for a transfer transaction at step 3, we still need a pile of gas to deploy a new contract at step 1. So that the reason we put 21.000+ gas-used in section 4.2.

However, it just inconvenience with some case like that, with some other cases, it's still helpful. For example, you want to reduce your power of vote.

Thus, in Kambria vote, we still support that kind of function and do one more option for voiding a vote.

In default, We commonly assign the first CID of the CID list, is a no-project CID (0x). For now, in order to void your vote, just simply vote for this CID and system will record that you revoked you vote.

With this solution, our voiding function becomes simpler, easier and cheaper, constantly around 30.016.

**5. Future works**

**5.1 Privacy**

In some cases, cause voter don't want to show their address and let anyone know they voted for whom, privacy become necessary. We plan to approach this problem by 2 ways, either A or B.

With A, we base on the anonymousness of votee. By using Differential privacy, we are possible to cover the relationship "Voter V had voted for Candidate C" but still ensure the final result is mathematically correct.

For naive example: We enforce voter to follow the voting rules. In detail, To make a vote, voter have to do 2 step. Step 1, voter must toss a coin, if heads, you would vote correctly (called true-vote) to your favorite candidate, if tails, you can choose either voting correctly or voting incorrectly (called wrong-vote). Step 2, following the step-1 result and making your vote.

Intuitively, the probability of tails and heads equal to 50%. With heads, true-vote is 100% and wrong-vote is 0%. With tails, true-vote is 50% and wrong-vote is 50% in case of people decision respecting Bernoulli(0.5) distribution.

We have,

    true-vote = 0.5 * 1 + 0.5 * 0.5 = 0.75
    wrong-vote = 0.5 * 0 + 0.5 * 0.5 = 0.25

Assume we are in a 2-candidate campaign, candidate C1 got 100 votes and candidate C2 got 160. So, How many votes that should be voted for C1, C2. Let x, y is honestly votes of C1, C2 respectively. Otherwise, in the total of 100 votes, we got 0.75 is honest and 0.25 is biased. The total of 160 is the same as x.

So,

    true-vote-for-C1 = 0.75 * 100
    wrong-vote-for-C1 = 0.25 * 100
    true-vote-for-C2 = 0.75 * 160
    wrong-vote-for-C2 = 0.25 * 160

And then,

    x = 0.75 * 100 + 0.25 * 160 = 115
    y = 0.75 * 160 + 0.25 * 100 = 145

Summary, we can announce that C2 won with 145 votes and C1 got 115 votes.

We can ensure Voter V voted with his balance B, but, because we don't know his toss is heads or tails so that cannot be sure which one he voted for (The anonymousness of votee).

With B, we get the other way by basing on the anonymousness of voter. To implement we need to find the solution to mix Voting system and zkSNARKs together. Basically, zkSNARKs is a protocol that helps ***Prover P can prove Verifier V that P knew the solution S of a riddle R without reveal S or any knowledge which V can use get gain an advantage to find the solution S afterward***.

In our case, We allow voters can vote secretly and make sure no one will know about it except voted candidate. Here we got a rule that "no one know accept voted candidate", Why is not "no one know even voted candidate"? The main reason is by this rule, a candidate will be able to know exactly how many votes he got, but the others candidate doesn't. Because votee know who with how much power voted for him, it's possible to him let another guy know about that. But the incentive is the votee will attempt to protect his voter, if he don't he will lose the reliance and the votes as well.

Then keep using zkSNARKs, votees will be able to prove the other candidates how many votes he get without revealing the voter's addresses or the voting transactions (The anonymousness voters). Every result would be ensured and un-rejectable cryptographically.