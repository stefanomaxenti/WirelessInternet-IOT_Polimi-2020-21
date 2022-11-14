/**
 *  Source file for implementation of module Middleware
 *  which provides the main logic for middleware message management
 *
 *  @author Luca Pietro Borsani
 */

generic module RandomGeneratorP() {

	provides interface Read<uint16_t>;

	uses interface Random;

} implementation {

	//***************** Boot interface ********************//
	command error_t Read.read(){
    signal Read.readDone( SUCCESS, call Random.rand16() );
	}
}
