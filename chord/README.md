# Perfect Squares

## Group Info
* Vineeth Chennapalli   - 31242465
* Prateek Arora         - 78190197

## Running Instructions

* Ensure that the mix.exs and chord.ex are present in the same directory. Run the following command with desired values of num_nodes and num_requests.
```
mix run chord.ex num_nodes num_requests
```

* Output Format: The average number of hops amde to find a specific key is printed.

## What Is Running

* The largest network we could successfully create and search keys upon consisted of 5000 nodes.
* Failure Model is also implemented and the details are provided below.

Case 1

```
mix run chord.ex 5000 100

Average number of hops to find keys are 5.736116
```


Case 2

```
mix run chord.ex 1000 200
Average number of hops to find keys are 4.58632
```

Case 3

```
mix run chord.ex 10050
Average number of hops to find keys are 2.9618
```

* FAILURE MODEL

Case 1

```
Average number of hops to find keys are 5.735976
Implementing the failure model now by killing a random node from the ring. . .
Killed node with PID: #PID<0.5964.0>
Average number of hops to find keys after single node failure are 5.73750950190038
```

Case 2

```
mix run chord.ex 1000 100
Average number of hops to find keys are 4.58665
Implementing the failure model now by killing a random node from the ring. . .
Killed node with PID: #PID<0.175.0>
Average number of hops to find keys after single node failure are 4.593783783783784
```

Case 3

```
mix run chord.ex 100 100
Average number of hops to find keys are 2.9778
Implementing the failure model now by killing a random node from the ring. . .
Killed node with PID: #PID<0.163.0>
Average number of hops to find keys after single node failure are 2.958787878787879
```




