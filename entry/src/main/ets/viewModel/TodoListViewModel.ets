import {common} from '@kit.AbilityKit';
import ThingViewModel from './ThingViewModel';
import TodoListModel from '../model/TodoListModel';

@Observed
export class ThingViewModelArray extends Array<ThingViewModel> {
}

@Observed
export default class TodoListViewModel  {
  @Track isChoosen: boolean = false;
  @Track things: ThingViewModelArray = new ThingViewModelArray();

  async loadTasks(context: common.UIAbilityContext) {
    let todoList = new TodoListModel([]);
    await todoList.loadTasks(context);

    for (let thing of todoList.things) {
      let todoListViewModel = new ThingViewModel();
      todoListViewModel.updateTask(thing);
      this.things.push(todoListViewModel);
    }
  }

  chooseAll(): void {
    for (let thing of this.things) {
      thing.isFinish = this.isChoosen;
    }

    this.isChoosen = !this.isChoosen;
  }


}
